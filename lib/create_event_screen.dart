
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  final ImagePicker imagePicker = ImagePicker();

  // Cloudinary configuration
  final String cloudName = 'z6watoie';
  final String uploadPreset = 'smartpass_events';

  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;

  // Select an image from the phone gallery.
  Future<void> pickImage() async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        if (!mounted) return;

        setState(() {
          selectedImage = image;
          selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select image: $e')),
      );
    }
  }

  // Upload image bytes directly to Cloudinary.
  Future<String> uploadImageToCloudinary() async {
    if (selectedImageBytes == null) {
      throw Exception('Please select an event image.');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        selectedImageBytes!,
        filename: 'smartpass_event.jpg',
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'] as String;
    } else {
      throw Exception('Cloudinary upload failed: $responseBody');
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  // Save the event after uploading its image.
  Future<void> createEvent() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        venueController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        quantityController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all details and select an event image.',
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(priceController.text.trim());
    final quantity = int.tryParse(quantityController.text.trim());

    if (price == null ||
        price < 0 ||
        quantity == null ||
        quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid price and ticket quantity.'),
        ),
      );
      return;
    }

    final organiser = FirebaseAuth.instance.currentUser;

    if (organiser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Step 1: Upload image to Cloudinary.
      final imageUrl = await uploadImageToCloudinary();

      // Step 2: Save event details in Firestore.
      await FirebaseFirestore.instance.collection('events').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'venue': venueController.text.trim(),
        'date': Timestamp.fromDate(selectedDate!),
        'time': selectedTime!.format(context),
        'price': price,
        'quantity': quantity,
        'organiserId': organiser.uid,
        'imageUrl': imageUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Event submitted successfully! Awaiting approval.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create event: $e'),
        ),
      );
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
    titleController.dispose();
    descriptionController.dispose();
    venueController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Information',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Provide the details of the event you want to organise.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            // Event poster section.
            const Text(
              'Event Poster',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: isLoading ? null : pickImage,
              child: Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: selectedImageBytes == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 45,
                      color: Color(0xFFF28C28),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tap to upload event poster',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Choose an image from your gallery',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    selectedImageBytes!,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (selectedImageBytes != null)
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                  setState(() {
                    selectedImage = null;
                    selectedImageBytes = null;
                  });
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove image'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),

            const SizedBox(height: 20),

            buildField(
              'Event Name',
              titleController,
              'Enter event name',
            ),

            buildField(
              'Description',
              descriptionController,
              'Describe your event',
              maxLines: 4,
            ),

            buildField(
              'Venue',
              venueController,
              'Enter event location',
            ),

            const SizedBox(height: 15),

            const Text(
              'Event Date',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  selectedDate == null
                      ? 'Select Event Date'
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Event Time',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  selectedTime == null
                      ? 'Select Event Time'
                      : selectedTime!.format(context),
                ),
              ),
            ),

            const SizedBox(height: 15),

            buildField(
              'Ticket Price (FCFA)',
              priceController,
              'Enter ticket price',
              keyboardType: TextInputType.number,
            ),

            buildField(
              'Available Tickets',
              quantityController,
              'Enter ticket quantity',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28C28),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  'Submit Event',
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

  Widget buildField(
      String label,
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
