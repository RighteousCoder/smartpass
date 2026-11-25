
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_profile_screen.dart';

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
          .update({'status': status});

      if (!context.mounted) return;

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
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }

  Future<void> deleteEvent(
      BuildContext context,
      String eventId,
      String eventTitle,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event?'),
          content: Text(
            'Are you sure you want to delete "$eventTitle"? '
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete event: $e')),
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
          // Admin Profile
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFFF28C28),
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const AdminProfileScreen(),
                ),
              );
            },
          ),

          // Logout
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
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
              'Manage Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load events.'),
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

                  final events = snapshot.data?.docs ?? [];

                  if (events.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 65,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'No events available.',
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
                    itemCount: events.length,

                    itemBuilder: (context, index) {
                      final event = events[index];
                      final data = event.data();

                      final eventId = event.id;
                      final title =
                          data['title']?.toString() ??
                              'Untitled Event';
                      final description =
                          data['description']?.toString() ?? '';
                      final venue =
                          data['venue']?.toString() ??
                              'Venue not specified';
                      final price = data['price'] ?? 0;
                      final quantity = data['quantity'] ?? 0;
                      final organiserId =
                          data['organiserId']?.toString() ?? '';
                      final status =
                          data['status']?.toString() ?? 'unknown';

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

                              const SizedBox(height: 8),

                              Text(
                                'Status: ${status.toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF28C28),
                                ),
                              ),

                              const SizedBox(height: 18),

                              if (status == 'pending')
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
                                          backgroundColor: Colors.red,
                                          foregroundColor:
                                          Colors.white,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    deleteEvent(
                                      context,
                                      eventId,
                                      title,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Delete Event',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
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
