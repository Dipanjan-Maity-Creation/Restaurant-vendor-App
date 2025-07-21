import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'settings_screen.dart';
import 'location_verification.dart'; // Import ConfirmLocationPage (ensure this exists)

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RestaurantEditScreen(),
    );
  }
}

class RestaurantEditScreen extends StatefulWidget {
  const RestaurantEditScreen({super.key});

  @override
  _RestaurantEditScreenState createState() => _RestaurantEditScreenState();
}

class _RestaurantEditScreenState extends State<RestaurantEditScreen> {
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final List<File?> _images = List.generate(4, (_) => null); // Local images
  final List<String> _imageUrls = List.filled(4, ''); // Fetched URLs from Firestore
  bool _isAddressEditable = true;
  bool _isLoading = true;
  bool _isSaving = false;


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user.uid)
            .collection('RestaurantDetails')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _restaurantNameController.text = data['restaurantName'] ?? '';
            _addressController.text = data['address'] ?? '';
            final List<String> urls = List<String>.from(data['images'] ?? []);
            _imageUrls.setAll(0, urls ?? List.filled(4, '')); // Populate fetched URLs
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _images[index] = File(image.path); // Set local image
      });
      await _uploadImage(index);
    }
  }

  Future<void> _uploadImage(int index) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _images[index] != null) {
      try {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('RestaurantImages')
            .child(user.uid)
            .child('image_$index.jpg');
        UploadTask uploadTask = ref.putFile(_images[index]!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _imageUrls[index] = downloadUrl; // Update URL after upload
          _images[index] = null; // Clear local image after upload
        });
        await _updateFirestore();
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<void> _updateFirestore() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user.uid)
            .collection('RestaurantDetails')
            .doc(user.uid)
            .update({
          'restaurantName': _restaurantNameController.text.trim(),
          'address': _addressController.text.trim(),
          'images': _imageUrls,
        });
      } catch (e) {
        print('Error updating Firestore: $e');
      }
    }
  }

  void _pickLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmLocationPage(
          currentAddress: _addressController.text,
        ),
      ),
    ).then((value) {
      if (value != null && value is String) {
        setState(() {
          _addressController.text = value; // Update address with returned value
          _isAddressEditable = true; // Re-enable address editing
        });
      } else {
        setState(() {
          _isAddressEditable = true; // Re-enable even if no address is returned
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
        title: const Text(
          'Edit Restaurant Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Restaurant Name and Address
            Text(
              'Restaurant Name',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _restaurantNameController,
              decoration: InputDecoration(
                hintText: 'Enter restaurant name',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black,
              ),
              cursorColor: Colors.black,
              cursorWidth: 0.9,
            ),
            SizedBox(height: 16),
            Text(
              'Address',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 3,
              readOnly: !_isAddressEditable,
              decoration: InputDecoration(
                hintText: 'Enter address',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black,
              ),
              cursorColor: Colors.black,
              cursorWidth: 0.9,
            ),
            SizedBox(height: 16),

            // Section 2: Pick Location Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _pickLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF1B6FF5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.location_on,
                  color: Color(0xFF1B6FF5),
                ),
                label: Text(
                  'Pick Location',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1B6FF5),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Section 3: Restaurant Photos
            Text(
              'Restaurant Photos',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: List.generate(4, (index) {
                return GestureDetector(
                  onTap: _images[index] != null
                      ? () => _pickImage(index) // Replace image if already present
                      : () => _pickImage(index), // Add new image if empty
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        if (_images[index] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _images[index]!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        else if (_imageUrls[index].isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imageUrls[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(child: Icon(Icons.error, color: Colors.red)),
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 8),
            Text(
              '${_images.where((image) => image != null).length + _imageUrls.where((url) => url.isNotEmpty).length}/4 photos uploaded',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
              setState(() {
                _isSaving = true;
              });
              await _updateFirestore();
              setState(() {
                _isSaving = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Details saved successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6FF5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isSaving
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}