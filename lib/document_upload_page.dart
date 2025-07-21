import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'instructions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DocumentUploadScreen(),
    );
  }
}

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  static File? savedAadhaarImage;

  File? _aadhaarImage;
  String? _aadhaarUrl;
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _upiHolderController = TextEditingController();
  bool _isUploading = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _aadhaarImage = savedAadhaarImage;
    _loadUploadedDocuments();
  }

  @override
  void dispose() {
    savedAadhaarImage = _aadhaarImage;
    _upiController.dispose();
    _upiHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadUploadedDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true);
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user.uid)
            .collection('UploadedDocuments')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _aadhaarUrl = doc['aadhaar'];
            _upiController.text = doc['upi'] ?? '';
            _upiHolderController.text = doc['upiHolderName'] ?? '';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'User not authenticated';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() {
        _aadhaarImage = File(image.path);
        _aadhaarUrl = null;
      });
    }
  }

  bool _isDataComplete() {
    final upi = _upiController.text.trim();
    final upiHolder = _upiHolderController.text.trim();
    return (_aadhaarImage != null || _aadhaarUrl != null) &&
        upi.isNotEmpty &&
        RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(upi) &&
        upiHolder.isNotEmpty &&
        RegExp(r'^[a-zA-Z\s.]{2,50}$').hasMatch(upiHolder);
  }

  Future<String> _uploadFile(File file, String folder, String fileName) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child(folder).child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask.timeout(const Duration(seconds: 30));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload $fileName: $e');
    }
  }

  Future<void> _saveUploadedDocuments() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      setState(() => _isUploading = false);
      return;
    }
    setState(() => _isUploading = true);
    try {
      await user.getIdToken(true);
      final Map<String, dynamic> details = {
        'upi': _upiController.text.trim(),
        'upiHolderName': _upiHolderController.text.trim(),
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      if (_aadhaarImage != null) {
        details['aadhaar'] = await _uploadFile(
            _aadhaarImage!, 'UploadedDocuments/${user.uid}', 'aadhaar.jpg');
      } else {
        details['aadhaar'] = _aadhaarUrl;
      }

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid)
          .collection('UploadedDocuments')
          .doc(user.uid);
      await docRef.set(details, SetOptions(merge: true));

      savedAadhaarImage = null;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InstructionsScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 0.0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Save Progress?', style: GoogleFonts.poppins()),
                    content: Text(
                        'Do you want to save your uploaded document and UPI details before exiting?',
                        style: GoogleFonts.poppins()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Discard', style: GoogleFonts.poppins()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Save', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _saveUploadedDocuments();
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            title: Text(
              'Document Upload',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDocumentSection(
                  title: 'Aadhaar Card',
                  image: _aadhaarImage,
                  url: _aadhaarUrl,
                  status: _aadhaarImage != null || _aadhaarUrl != null
                      ? 'Uploaded'
                      : 'Pending',
                  statusColor: _aadhaarImage != null || _aadhaarUrl != null
                      ? Colors.green
                      : Colors.orange,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 16),
                Text(
                  'UPI Details',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Enter UPI ID',
                  child: TextField(
                    controller: _upiController,
                    decoration: InputDecoration(
                      labelText: 'UPI ID (e.g., name@bank)',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      errorText: _upiController.text.isNotEmpty &&
                          !RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$')
                              .hasMatch(_upiController.text)
                          ? 'Enter a valid UPI ID'
                          : null,
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\w@.-]')),
                    ],
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Enter UPI Holder Name',
                  child: TextField(
                    controller: _upiHolderController,
                    decoration: InputDecoration(
                      labelText: 'UPI Holder Name',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      errorText: _upiHolderController.text.isNotEmpty &&
                          !RegExp(r'^[a-zA-Z\s.]{2,50}$')
                              .hasMatch(_upiHolderController.text)
                          ? 'Enter a valid name (2-50 characters, letters and spaces only)'
                          : null,
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.]')),
                    ],
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isDataComplete() && !_isUploading && !_isLoading
                    ? _saveUploadedDocuments
                    : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please upload Aadhaar Card, enter a valid UPI ID, and UPI holder name')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6FF5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Complete Setup',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B6FF5)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required File? image,
    required String? url,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: (image == null && url == null)
              ? DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            color: Colors.grey,
            strokeWidth: 1,
            dashPattern: const [6, 3],
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload,
                    color: Color(0xFF1B6FF5),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click to upload or take photo',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
              : Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image != null
                      ? Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    cacheWidth: 300,
                    cacheHeight: 200,
                  )
                      : CachedNetworkImage(
                    imageUrl: url!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Color(0xFF1B6FF5),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}