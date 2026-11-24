
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> updateEventStatus(
      BuildContext context,
      String eventId,
      String status,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .update({
        'status': status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'published'
                ? 'Event approved successfully!'
                : 'Event rejected successfully!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Smart Pass Admin',
          style: TextStyle(
            color: Color(0xFFF28C28),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.popUntil(
                  context,
                      (route) => route.isFirst,
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Review and manage events submitted by organisers.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Pending Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Unable to load events.',
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF28C28),
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 65,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 15),

                          Text(
                            'No pending events.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,

                    itemBuilder: (context, index) {
                      final event =
                      snapshot.data!.docs[index];

                      final eventId = event.id;

                      final title =
                          event['title'] ?? 'Untitled Event';

                      final description =
                          event['description'] ?? '';

                      final venue =
                          event['venue'] ?? 'Venue not specified';

                      final price =
                          event['price'] ?? 0;

                      final quantity =
                          event['quantity'] ?? 0;

                      final organiserId =
                          event['organiserId'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 18,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(description),

                              const SizedBox(height: 12),

                              Text('Venue: $venue'),

                              Text('Ticket price: $price FCFA'),

                              Text('Available tickets: $quantity'),

                              const SizedBox(height: 8),

                              Text(
                                'Organiser ID: $organiserId',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        updateEventStatus(
                                          context,
                                          eventId,
                                          'published',
                                        );
                                      },

                                      style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.green,
                                        foregroundColor:
                                        Colors.white,
                                      ),

                                      child: const Text('Approve'),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        updateEventStatus(
                                          context,
                                          eventId,
                                          'rejected',
                                        );
                                      },

                                      style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.red,
                                        foregroundColor:
                                        Colors.white,
                                      ),

                                      child: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
