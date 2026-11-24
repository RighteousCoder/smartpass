
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { randomUUID } = require('crypto');

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const serviceAccount = require('./serviceAccountKey.json.json');

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();
const auth = getAuth();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Verify Firebase login
async function verifyToken(req, res, next) {
  try {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith('Bearer ')) {
      return res.status(401).json({
        status: 'error',
        message: 'Authentication token is required.',
      });
    }

    const token = authorization.split(' ')[1];
    req.user = await auth.verifyIdToken(token);

    next();
  } catch (error) {
    return res.status(401).json({
      status: 'error',
      message: 'Invalid or expired authentication token.',
    });
  }
}

// Connect to MeSomb
async function getMeSombClient() {
  const {
    MESOMB_APPLICATION_KEY,
    MESOMB_ACCESS_KEY,
    MESOMB_SECRET_KEY,
  } = process.env;

  if (
    !MESOMB_APPLICATION_KEY ||
    !MESOMB_ACCESS_KEY ||
    !MESOMB_SECRET_KEY
  ) {
    throw new Error('MeSomb credentials are missing.');
  }

  const { PaymentOperation } = await import('@hachther/mesomb');

  return new PaymentOperation({
    applicationKey: MESOMB_APPLICATION_KEY,
    accessKey: MESOMB_ACCESS_KEY,
    secretKey: MESOMB_SECRET_KEY,
  });
}

// Home
app.get('/', (req, res) => {
  res.json({
    message: 'Smart Pass backend is running!',
    firebase: 'Connected successfully!',
    payment: 'MeSomb configured',
    status: 'success',
  });
});

// Protected route
app.get('/protected', verifyToken, (req, res) => {
  res.json({
    status: 'success',
    message: 'You are authenticated!',
    userId: req.user.uid,
    email: req.user.email,
  });
});

// Test Firestore
app.get('/test-firebase', async (req, res) => {
  try {
    const snapshot = await db.collection('events').limit(1).get();

    res.json({
      status: 'success',
      message: 'Firestore connected successfully!',
      documentsFound: snapshot.size,
    });
  } catch (error) {
    console.error('Firestore test failed:', error);

    res.status(500).json({
      status: 'error',
      message: 'Could not access Firestore.',
    });
  }
});

// CREATE ME SOMB PAYMENT
app.post('/mesomb/event-payment', verifyToken, async (req, res) => {
  try {
    const { eventId, payer, service } = req.body;

    if (!eventId || typeof eventId !== 'string') {
      return res.status(400).json({
        status: 'error',
        message: 'Event ID is required.',
      });
    }

    // Cameroon local mobile number: 9 digits
    const phone = String(payer || '').replace(/\s+/g, '');

    if (!/^6\d{8}$/.test(phone)) {
      return res.status(400).json({
        status: 'error',
        message: 'Enter a valid Cameroon Mobile Money number, e.g. 670000000.',
      });
    }

    const network = String(service || '').toUpperCase();

    if (!['MTN', 'ORANGE'].includes(network)) {
      return res.status(400).json({
        status: 'error',
        message: 'Select MTN or ORANGE.',
      });
    }

    // Read event from Firestore
    const eventRef = db.collection('events').doc(eventId);
    const eventSnapshot = await eventRef.get();

    if (!eventSnapshot.exists) {
      return res.status(404).json({
        status: 'error',
        message: 'Event not found.',
      });
    }

    const event = eventSnapshot.data();

    if (event.status !== 'published') {
      return res.status(400).json({
        status: 'error',
        message: 'This event is not available for booking.',
      });
    }

    const price = Number(event.price);
    const quantity = Number(event.quantity);

    if (!Number.isFinite(price) || price < 100) {
      return res.status(400).json({
        status: 'error',
        message: 'Event price must be at least 100 FCFA.',
      });
    }

    if (!Number.isFinite(quantity) || quantity <= 0) {
      return res.status(400).json({
        status: 'error',
        message: 'No tickets are currently available.',
      });
    }

    const amount = Math.round(price);
    const client = await getMeSombClient();

    // Start payment collection
    const response = await client.makeCollect({
      nonce: randomUUID(),
      amount,
      payer: phone,
      service: network,
      country: 'CM',
      currency: 'XAF',
      mode: 'synchronous',
      message: `Smart Pass ticket: ${event.title || 'Event'}`,
      reference: event.title || 'Smart Pass ticket',
      trxID: `SP-${randomUUID()}`,
    });

    if (!response.isOperationSuccess()) {
      throw new Error(
        response.message || 'MeSomb could not process the payment request.'
      );
    }

    const transaction = response.transaction;

    if (!transaction || !transaction.pk) {
      throw new Error('MeSomb did not return a transaction ID.');
    }

    const transId = transaction.pk;
    const paymentStatus = String(transaction.status || 'PENDING').toUpperCase();

    // Save payment in Firestore
    await db.collection('payments').doc(transId).set({
      userId: req.user.uid,
      eventId,
      eventTitle: event.title || 'Event',
      amount,
      payer: phone,
      service: network,
      transId,
      status: paymentStatus,
      ticketIssued: false,
      createdAt: new Date(),
    });

    res.json({
      status: 'success',
      message: 'Payment request sent. Check your phone to authorize payment.',
      transId,
      amount,
      paymentStatus,
    });

  } catch (error) {
    console.error('MeSomb payment error:', error);

    res.status(500).json({
      status: 'error',
      message: error.message || 'Could not create payment.',
    });
  }
});

// VERIFY PAYMENT AND ISSUE TICKET
app.get(
  '/mesomb/payment-status/:transId',
  verifyToken,
  async (req, res) => {
    try {
      const transId = req.params.transId;

      const paymentRef = db.collection('payments').doc(transId);
      const paymentSnapshot = await paymentRef.get();

      if (
        !paymentSnapshot.exists ||
        paymentSnapshot.data().userId !== req.user.uid
      ) {
        return res.status(404).json({
          status: 'error',
          message: 'Payment not found.',
        });
      }

      const savedPayment = paymentSnapshot.data();

      // Do not issue the same ticket twice
      if (savedPayment.ticketIssued) {
        const existingTicket = await db.collection('tickets').doc(transId).get();

        return res.json({
          status: 'success',
          paymentStatus: 'SUCCESS',
          ticketIssued: true,
          ticket: existingTicket.exists ? existingTicket.data() : null,
        });
      }

      const client = await getMeSombClient();

      // Ask MeSomb for the real transaction status
      const transactions = await client.checkTransactions([transId]);

      const transaction = Array.isArray(transactions)
        ? transactions.find((item) => item.pk === transId)
        : null;

      if (!transaction) {
        return res.status(404).json({
          status: 'error',
          message: 'Transaction not found at MeSomb.',
        });
      }

      const paymentStatus = String(transaction.status || '').toUpperCase();

      await paymentRef.update({
        status: paymentStatus,
        lastCheckedAt: new Date(),
      });

      // Only SUCCESS is a completed successful payment
      if (paymentStatus !== 'SUCCESS') {
        return res.json({
          status: 'success',
          paymentStatus,
          ticketIssued: false,
          message: 'Payment has not been confirmed yet.',
        });
      }

      // Confirm amount
      if (Number(transaction.amount) !== Number(savedPayment.amount)) {
        return res.status(400).json({
          status: 'error',
          message: 'Payment amount does not match the ticket price.',
        });
      }

      const eventRef = db.collection('events').doc(savedPayment.eventId);
      const ticketRef = db.collection('tickets').doc(transId);

      // Issue ticket only once
      const ticket = await db.runTransaction(async (transactionDb) => {
        const latestPayment = await transactionDb.get(paymentRef);
        const existingTicket = await transactionDb.get(ticketRef);

        if (!latestPayment.exists) {
          throw new Error('Payment record no longer exists.');
        }

        if (existingTicket.exists) {
          transactionDb.update(paymentRef, {
            ticketIssued: true,
          });

          return existingTicket.data();
        }

        const eventSnapshot = await transactionDb.get(eventRef);

        if (!eventSnapshot.exists) {
          throw new Error('Event no longer exists.');
        }

        const event = eventSnapshot.data();
        const availableTickets = Number(event.quantity);

        if (
          !Number.isFinite(availableTickets) ||
          availableTickets <= 0
        ) {
          throw new Error(
            'Payment succeeded, but no tickets remain. Please contact the organiser.'
          );
        }

        const ticketData = {
          ticketId: transId,
          transId,
          eventId: savedPayment.eventId,
          eventTitle: savedPayment.eventTitle,
          userId: req.user.uid,
          userEmail: req.user.email || '',
          amount: savedPayment.amount,
          status: 'valid',
          createdAt: new Date(),
        };

        transactionDb.update(eventRef, {
          quantity: availableTickets - 1,
        });

        transactionDb.set(ticketRef, ticketData);

        transactionDb.update(paymentRef, {
          status: 'SUCCESS',
          ticketIssued: true,
          ticketIssuedAt: new Date(),
        });

        return ticketData;
      });

      res.json({
        status: 'success',
        paymentStatus: 'SUCCESS',
        ticketIssued: true,
        ticket,
        message: 'Payment successful. Your ticket has been issued!',
      });

    } catch (error) {
      console.error('Payment verification error:', error);

      res.status(500).json({
        status: 'error',
        message: error.message || 'Could not verify payment.',
      });
    }
  }
);

// Start server
app.listen(PORT, () => {
  console.log(`Smart Pass backend running on port ${PORT}`);
  console.log('Firebase Admin SDK connected successfully!');
});
