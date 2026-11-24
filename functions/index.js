
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const express = require("express");
const cors = require("cors");

initializeApp();

const db = getFirestore();
const auth = getAuth();

const FAPSHI_API_USER = defineSecret("FAPSHI_API_USER");
const FAPSHI_API_KEY = defineSecret("FAPSHI_API_KEY");

const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

async function verifyToken(req, res, next) {
  try {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith("Bearer ")) {
      return res.status(401).json({
        status: "error",
        message: "Authentication token is required.",
      });
    }

    const token = authorization.split(" ")[1];
    req.user = await auth.verifyIdToken(token);
    next();
  } catch (error) {
    return res.status(401).json({
      status: "error",
      message: "Invalid or expired authentication token.",
    });
  }
}

async function getFapshiClient() {
  const { createFapshiClient } = await import("@fapshi/payments");

  return createFapshiClient({
    apiUser: FAPSHI_API_USER.value(),
    apiKey: FAPSHI_API_KEY.value(),
    environment: "live",
  });
}

app.get("/", (req, res) => {
  res.json({
    message: "Smart Pass payment API is running!",
    status: "success",
  });
});

// CREATE PAYMENT
app.post("/fapshi/event-payment", verifyToken, async (req, res) => {
  try {
    const { eventId } = req.body;

    if (!eventId || typeof eventId !== "string") {
      return res.status(400).json({
        status: "error",
        message: "Event ID is required.",
      });
    }

    const eventRef = db.collection("events").doc(eventId);
    const eventSnapshot = await eventRef.get();

    if (!eventSnapshot.exists) {
      return res.status(404).json({
        status: "error",
        message: "Event not found.",
      });
    }

    const event = eventSnapshot.data();

    if (event.status !== "published") {
      return res.status(400).json({
        status: "error",
        message: "This event is not available for booking.",
      });
    }

    const price = Number(event.price);
    const quantity = Number(event.quantity);

    if (!Number.isFinite(price) || price < 100) {
      return res.status(400).json({
        status: "error",
        message: "Event price must be at least 100 FCFA.",
      });
    }

    if (!Number.isFinite(quantity) || quantity <= 0) {
      return res.status(400).json({
        status: "error",
        message: "No tickets are currently available.",
      });
    }

    const amount = Math.round(price);
    const fapshi = await getFapshiClient();

    const payment = await fapshi.initiatePay({
      amount,
      email: req.user.email,
      userId: req.user.uid,
      externalId: `SP-${Date.now()}`,
      message: `Smart Pass ticket: ${event.title || "Event"}`,
    });

    if (!payment.link || !payment.transId) {
      throw new Error("Fapshi did not return a payment link.");
    }

    await db.collection("payments").doc(payment.transId).set({
      userId: req.user.uid,
      eventId,
      eventTitle: event.title || "Event",
      amount,
      transId: payment.transId,
      status: "PENDING",
      ticketIssued: false,
      createdAt: new Date(),
    });

    return res.json({
      status: "success",
      message: "Payment link created.",
      paymentLink: payment.link,
      transId: payment.transId,
      amount,
    });
  } catch (error) {
    console.error("Fapshi payment error:", error);
    return res.status(500).json({
      status: "error",
      message: error.message || "Could not create payment.",
    });
  }
});

// VERIFY PAYMENT AND ISSUE TICKET
app.get(
  "/fapshi/payment-status/:transId",
  verifyToken,
  async (req, res) => {
    try {
      const transId = req.params.transId;
      const paymentRef = db.collection("payments").doc(transId);
      const paymentSnapshot = await paymentRef.get();

      if (
        !paymentSnapshot.exists ||
        paymentSnapshot.data().userId !== req.user.uid
      ) {
        return res.status(404).json({
          status: "error",
          message: "Payment not found.",
        });
      }

      const savedPayment = paymentSnapshot.data();

      const fapshi = await getFapshiClient();
      const transaction = await fapshi.getPaymentStatus(transId);
      const paymentStatus = String(transaction.status).toUpperCase();

      await paymentRef.update({
        status: paymentStatus,
        lastCheckedAt: new Date(),
      });

      if (paymentStatus !== "SUCCESSFUL") {
        return res.json({
          status: "success",
          paymentStatus,
          ticketIssued: false,
          message: "Payment has not been confirmed yet.",
        });
      }

      if (Number(transaction.amount) !== Number(savedPayment.amount)) {
        return res.status(400).json({
          status: "error",
          message: "Payment amount does not match the ticket price.",
        });
      }

      const eventRef = db.collection("events").doc(savedPayment.eventId);
      const ticketRef = db.collection("tickets").doc(transId);

      const ticket = await db.runTransaction(async (transactionDb) => {
        const latestPayment = await transactionDb.get(paymentRef);
        const existingTicket = await transactionDb.get(ticketRef);

        if (!latestPayment.exists) {
          throw new Error("Payment record not found.");
        }

        if (existingTicket.exists) {
          transactionDb.update(paymentRef, {
            ticketIssued: true,
          });
          return existingTicket.data();
        }

        const eventSnapshot = await transactionDb.get(eventRef);

        if (!eventSnapshot.exists) {
          throw new Error("Event no longer exists.");
        }

        const event = eventSnapshot.data();
        const availableTickets = Number(event.quantity);

        if (
          !Number.isFinite(availableTickets) ||
          availableTickets <= 0
        ) {
          throw new Error(
            "Payment succeeded, but no tickets remain. Please contact the organiser."
          );
        }

        const ticketData = {
          ticketId: transId,
          transId,
          eventId: savedPayment.eventId,
          eventTitle: savedPayment.eventTitle,
          userId: req.user.uid,
          userEmail: req.user.email || "",
          amount: savedPayment.amount,
          status: "valid",
          createdAt: new Date(),
        };

        transactionDb.update(eventRef, {
          quantity: availableTickets - 1,
        });

        transactionDb.set(ticketRef, ticketData);

        transactionDb.update(paymentRef, {
          status: "SUCCESSFUL",
          ticketIssued: true,
          ticketIssuedAt: new Date(),
        });

        return ticketData;
      });

      return res.json({
        status: "success",
        paymentStatus: "SUCCESSFUL",
        ticketIssued: true,
        ticket,
        message: "Payment successful. Your ticket has been issued!",
      });
    } catch (error) {
      console.error("Payment verification error:", error);
      return res.status(500).json({
        status: "error",
        message: error.message || "Could not verify payment.",
      });
    }
  }
);

exports.api = onRequest(
  {
    region: "europe-west1",
    secrets: [FAPSHI_API_USER, FAPSHI_API_KEY],
  },
  app
);
