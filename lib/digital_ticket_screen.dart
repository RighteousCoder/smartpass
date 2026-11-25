
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DigitalTicketScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const DigitalTicketScreen({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final ticketId = (ticket['ticketId'] ?? '').toString();
    final eventTitle = ticket['eventTitle'] ?? 'Event';
    final amount = ticket['amount'] ?? 0;
    final status = (ticket['status'] ?? 'unknown').toString();

    final createdAt = ticket['createdAt'];

    String purchaseDate = 'Not available';

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      purchaseDate = '${date.day}/${date.month}/${date.year}';
    }

    final isValid = status.toLowerCase() == 'valid';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Digital Ticket',
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Text(
                    'SMART PASS',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'YOUR DIGITAL EVENT TICKET',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),

                  const Divider(height: 35),

                  Text(
                    eventTitle.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  if (ticketId.isNotEmpty)
                    QrImageView(
                      data: ticketId,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    )
                  else
                    const Text('Ticket QR code unavailable.'),

                  const SizedBox(height: 12),

                  const Text(
                    'Show this QR code at the event entrance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const Divider(height: 35),

                  _ticketDetail('Ticket ID', ticketId),
                  _ticketDetail('Amount paid', 'FCFA $amount'),
                  _ticketDetail('Purchase date', purchaseDate),

                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: isValid
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isValid
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: isValid
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isValid
                              ? 'PURCHASED - VALID'
                              : status.toUpperCase(),
                          style: TextStyle(
                            color: isValid
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Keep this ticket safe. Each ticket has a unique QR code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticketDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
