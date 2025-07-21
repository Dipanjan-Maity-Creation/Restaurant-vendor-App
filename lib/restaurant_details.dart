import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'location_verification.dart';
import 'document_upload_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CreateProfileScreen(),
    );
  }
}

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen>
    with AutomaticKeepAliveClientMixin {
  static String savedRestaurantName = "";
  static String savedFssai = "";
  static String savedCity = "";
  static String savedPincode = "";
  static String savedAddress = "";
  static double? savedLatitude;
  static double? savedLongitude;
  static List<File?> savedImages = List.generate(4, (_) => null);

  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _fssaiController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isAddressEditable = true;
  double? _latitude;
  double? _longitude;

  final List<File?> _images = List.generate(4, (_) => null);
  bool _isUploading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _restaurantNameController.text = savedRestaurantName;
    _fssaiController.text = savedFssai;
    _cityController.text = savedCity;
    _pincodeController.text = savedPincode;
    _addressController.text = savedAddress;
    _latitude = savedLatitude;
    _longitude = savedLongitude;
    for (int i = 0; i < savedImages.length; i++) {
      _images[i] = savedImages[i];
    }

    _restaurantNameController.addListener(() => setState(() {}));
    _fssaiController.addListener(() => setState(() {}));
    _cityController.addListener(() => setState(() {}));
    _pincodeController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    savedRestaurantName = _restaurantNameController.text;
    savedFssai = _fssaiController.text;
    savedCity = _cityController.text;
    savedPincode = _pincodeController.text;
    savedAddress = _addressController.text;
    savedLatitude = _latitude;
    savedLongitude = _longitude;
    for (int i = 0; i < _images.length; i++) {
      savedImages[i] = _images[i];
    }

    _restaurantNameController.dispose();
    _fssaiController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _images[index] = File(image.path);
      });
    }
  }

  Future<void> _pickLocation() async {
    final value = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmLocationPage(
          currentAddress: _addressController.text,
        ),
      ),
    );
    if (value != null && value is Map<String, dynamic>) {
      setState(() {
        _addressController.text = value['address'];
        _latitude = value['latitude'];
        _longitude = value['longitude'];
        _isAddressEditable = true; // Keep editable to match RestaurantEditScreen
      });
    } else {
      setState(() {
        _isAddressEditable = true;
      });
    }
  }

  Future<List<String>> _uploadImages(String uid) async {
    List<String> downloadUrls = [];
    for (int i = 0; i < _images.length; i++) {
      if (_images[i] != null) {
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('RestaurantImages')
            .child(uid)
            .child('image_$i.jpg');
        UploadTask uploadTask = ref.putFile(_images[i]!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
    }
    return downloadUrls;
  }

  Future<void> _saveRestaurantDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user signed in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user signed in')),
      );
      return;
    }

    List<String> uploadedImageUrls = [];
    try {
      uploadedImageUrls = await _uploadImages(user.uid);
    } catch (e) {
      print('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload images: $e')),
      );
      return;
    }

    final Map<String, dynamic> details = {
      'restaurantName': _restaurantNameController.text.trim(),
      'fssaiLicenseNumber': _fssaiController.text.trim(),
      'city': _cityController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'address': _addressController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'images': uploadedImageUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid)
          .collection('RestaurantDetails')
          .doc(user.uid)
          .set(details, SetOptions(merge: true));
      print('Successfully saved RestaurantDetails for ${user.uid}');
    } catch (e) {
      print('Error saving to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save details: $e')),
      );
    }
  }

  bool _areFieldsFilled() {
    bool hasAtLeastOnePhoto = _images.any((image) => image != null);
    return _restaurantNameController.text.isNotEmpty &&
        _fssaiController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _pincodeController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        hasAtLeastOnePhoto;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 0.0,
            title: Text(
              'Restaurant Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  'FSSAI License Number',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _fssaiController,
                  decoration: InputDecoration(
                    hintText: 'Enter FSSAI license number',
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
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  cursorColor: Colors.black,
                  cursorWidth: 0.9,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              hintText: 'Enter city',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            cursorColor: Colors.black,
                            cursorWidth: 0.9,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pincode',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _pincodeController,
                            decoration: InputDecoration(
                              hintText: 'Enter pincode',
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            cursorColor: Colors.black,
                            cursorWidth: 0.9,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  cursorColor: Colors.black,
                  cursorWidth: 0.9,
                ),
                SizedBox(height: 16),
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
                Text(
                  'Upload Photos',
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
                      onTap: () => _pickImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _images[index] == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
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
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _images[index]!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _areFieldsFilled()
                    ? () async {
                  setState(() {
                    _isUploading = true;
                  });
                  await _saveRestaurantDetails();
                  setState(() {
                    _isUploading = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DocumentUploadScreen(),
                    ),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6FF5),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B6FF5)),
              ),
            ),
          ),
      ],
    );
  }
}