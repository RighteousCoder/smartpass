
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesomb/mesomb.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() =>
      _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final phoneController = TextEditingController();

  String selectedNetwork = 'MTN';
  bool isLoading = false;

  // MeSomb credentials:
  // Application Key, Access Key, Secret Key.
  // Enter your regenerated keys locally.
  final payment = PaymentOperation(
    '3a76f47d82d3e2a1b4aa3c13f580b19d35b58159',
    'sk_live_Fr1JxKxkmlyiU5Ii8yzuGd-C8nHXmqXxTk_6IztPh3s',
    '52f2c10f-fb1f-47b8-80cd-d5852b857c21',
  );

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toString().split(' ')[0];
    }
    return value?.toString() ?? 'Not specified';
  }

  Future<void> buyTicket() async {
    if (isLoading) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please log in before buying a ticket.');
      return;
    }

    final phone = phoneController.text.trim();

    if (!RegExp(r'^(6[0-9]{8})$').hasMatch(phone)) {
      showMessage(
        'Enter a valid Cameroon number, e.g. 677550203.',
      );
      return;
    }

    final eventId = widget.event['id']?.toString();

    debugPrint('EVENT ID: $eventId');
    debugPrint('SIGNED IN USER: ${user.uid}');

    if (eventId == null || eventId.isEmpty) {
      showMessage('Event ID is missing.');
      return;
    }

    final amount =
        (widget.event['price'] as num?)?.round() ?? 0;

    if (amount <= 0) {
      showMessage('Invalid ticket price.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint('STEP 1: Checking event in Firestore');

      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(eventId);

      final eventSnapshot = await eventRef.get();

      debugPrint('STEP 2: Event read successful');

      if (!eventSnapshot.exists) {
        throw Exception('Event does not exist.');
      }

      final available =
          (eventSnapshot.data()?['quantity'] as num?)
              ?.toInt() ??
              0;

      if (available <= 0) {
        throw Exception('All tickets have been sold.');
      }

      debugPrint('STEP 3: Starting MeSomb payment');

      final response = await payment.makeCollect(
        amount: amount.toDouble(),
        service: selectedNetwork,
        payer: phone,
        country: 'CM',
        currency: 'XAF',
      );

      debugPrint('STEP 4: MeSomb response received');
      debugPrint('Payment success: ${response.success}');
      debugPrint(
        'Transaction success: ${response.transaction.success}',
      );

      if (response.success != true ||
          response.transaction.success != true) {
        throw Exception(
          'MeSomb did not confirm the payment.',
        );
      }

      debugPrint('STEP 5: Saving ticket in Firestore');

      final firestore = FirebaseFirestore.instance;

      final paymentRef =
      firestore.collection('payments').doc();

      final ticketRef =
      firestore.collection('tickets').doc();

      await firestore.runTransaction((transaction) async {
        final latestEvent = await transaction.get(eventRef);

        if (!latestEvent.exists) {
          throw Exception('Event not found.');
        }

        final latestQuantity =
            (latestEvent.data()?['quantity'] as num?)
                ?.toInt() ??
                0;

        if (latestQuantity <= 0) {
          throw Exception('No tickets remain.');
        }

        transaction.update(eventRef, {
          'quantity': latestQuantity - 1,
        });

        transaction.set(paymentRef, {
          'userId': user.uid,
          'eventId': eventId,
          'eventTitle': widget.event['title'] ?? '',
          'amount': amount,
          'phone': phone,
          'network': selectedNetwork,
          'status': 'successful',
          'ticketIssued': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.set(ticketRef, {
          'ticketId': ticketRef.id,
          'eventId': eventId,
          'eventTitle': widget.event['title'] ?? '',
          'userId': user.uid,
          'userEmail': user.email ?? '',
          'amount': amount,
          'status': 'valid',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('STEP 6: Ticket successfully saved');

      if (!mounted) return;

      showMessage(
        'Payment successful! Your ticket has been issued.',
      );
    } catch (error, stackTrace) {
      debugPrint('PAYMENT ERROR: $error');
      debugPrint('$stackTrace');

      if (mounted) {
        showMessage(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    final imageUrl = event['imageUrl']?.toString() ?? '';
    final quantity = event['quantity'] ?? 0;
    final price = event['price'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox(
                      height: 150,
                      child: Center(
                        child: Icon(Icons.event, size: 60),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            Text(
              event['title'] ?? 'Event',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              event['description'] ??
                  'No description available.',
            ),

            const SizedBox(height: 20),

            Text(
              'Venue: ${event['venue'] ?? 'Not specified'}',
            ),

            const SizedBox(height: 8),

            Text('Date: ${formatDate(event['date'])}'),

            const SizedBox(height: 8),

            Text(
              'Time: ${event['time'] ?? 'Not specified'}',
            ),

            const SizedBox(height: 8),

            Text('Ticket price: $price FCFA'),

            const SizedBox(height: 8),

            Text('Available tickets: $quantity'),

            const SizedBox(height: 25),

            const Text(
              'Payment details',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Money number',
                hintText: '677550203',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedNetwork,
              decoration: const InputDecoration(
                labelText: 'Select payment network',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'MTN',
                  child: Text('MTN Mobile Money'),
                ),
                DropdownMenuItem(
                  value: 'ORANGE',
                  child: Text('Orange Money'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedNetwork = value;
                  });
                }
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : buyTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28C28),
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  'Buy Ticket',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
