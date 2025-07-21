import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_screen.dart';

class PayoutDetailsPage extends StatefulWidget {
  const PayoutDetailsPage({super.key});

  @override
  State<PayoutDetailsPage> createState() => _PayoutDetailsPageState();
}

class _PayoutDetailsPageState extends State<PayoutDetailsPage> {
  // Controllers for the text fields
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  // Track if data exists to toggle between "Save Details" and "Edit Details"
  bool _isDataSaved = false;

  // Store the original data to compare for updates
  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _fetchBankDetails(); // Fetch data when the page loads
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _upiController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  // Fetch existing bank details from Firestore
  Future<void> _fetchBankDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = user.uid;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(uid)
          .collection('OwnerDetails')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('BankDetails')) {
          final bankDetails = data['BankDetails'] as Map<String, dynamic>;
          setState(() {
            _upiController.text = bankDetails['upiId'] ?? '';
            _accountNumberController.text = bankDetails['accountNumber'] ?? '';
            _ifscController.text = bankDetails['ifscCode'] ?? '';
            _accountHolderController.text =
                bankDetails['accountHolderName'] ?? '';
            _isDataSaved = true; // Data exists, show "Edit Details"
            _originalData = Map<String, dynamic>.from(
                bankDetails); // Store original data for comparison
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch bank details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Validation logic for bank details
  bool _validateBankDetails() {
    final upiId = _upiController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final ifscCode = _ifscController.text.trim();
    final accountHolderName = _accountHolderController.text.trim();

    // Case 1: If only UPI ID is filled, allow saving without warnings
    if (upiId.isNotEmpty &&
        accountNumber.isEmpty &&
        ifscCode.isEmpty &&
        accountHolderName.isEmpty) {
      return true;
    }

    // Case 2: If bank account number is entered, IFSC code and account holder name are required
    if (accountNumber.isNotEmpty) {
      if (ifscCode.isEmpty || accountHolderName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please fill in IFSC code and account holder name to save bank details.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    // Case 3: If IFSC code and account holder name are entered, bank account number is required
    if (ifscCode.isNotEmpty &&
        accountHolderName.isNotEmpty &&
        accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in the bank account number to save bank details.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Case 4: If bank account number and IFSC code are entered, account holder name is required
    if (accountNumber.isNotEmpty &&
        ifscCode.isNotEmpty &&
        accountHolderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in the account holder name to save bank details.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // If none of the fields are filled, show a warning
    if (upiId.isEmpty &&
        accountNumber.isEmpty &&
        ifscCode.isEmpty &&
        accountHolderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please fill in at least the UPI ID or all bank details to save.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  // Save or update bank details to Firestore
  Future<void> _saveBankDetails() async {
    // Validate the input fields
    if (!_validateBankDetails()) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = user.uid;
    final upiId = _upiController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final ifscCode = _ifscController.text.trim();
    final accountHolderName = _accountHolderController.text.trim();

    // Prepare the updated data
    final updatedBankDetails = <String, dynamic>{};

    // Only include fields that have changed
    if (upiId != (_originalData['upiId'] ?? '')) {
      updatedBankDetails['upiId'] = upiId;
    }
    if (accountNumber != (_originalData['accountNumber'] ?? '')) {
      updatedBankDetails['accountNumber'] = accountNumber;
    }
    if (ifscCode != (_originalData['ifscCode'] ?? '')) {
      updatedBankDetails['ifscCode'] = ifscCode;
    }
    if (accountHolderName != (_originalData['accountHolderName'] ?? '')) {
      updatedBankDetails['accountHolderName'] = accountHolderName;
    }

    // Always update the timestamp
    updatedBankDetails['updatedAt'] = FieldValue.serverTimestamp();

    try {
      // If no fields have changed, show a message and return
      if (updatedBankDetails.length <= 1) {
        // Only 'updatedAt' would be present if no fields changed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Save or update in Firestore
      await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(uid)
          .collection('OwnerDetails')
          .doc(uid)
          .set(
              {
            'BankDetails': updatedBankDetails,
          },
              SetOptions(
                  merge:
                      true)); // Use merge to update only the specified fields

      // Update the original data to reflect the new values
      setState(() {
        _originalData = {
          'upiId': upiId,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
          'accountHolderName': accountHolderName,
        };
        _isDataSaved = true; // Ensure the button shows "Edit Details"
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to SettingsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save bank details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor:
            const Color(0xFFFFFFFF), // Background color #FFFFFF
      ),
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leadingWidth: 40,
          backgroundColor: Colors.white,
          titleSpacing: 0,
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
            'Payout Details',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instruction text with off-white background
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, // Off-white background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF1B6FF5), // Icon color as requested
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fill in these details before requesting a payout',
                        style: TextStyle(
                          color: Colors.black, // Text color changed to black
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // UPI ID Field
              _buildTextField(
                controller: _upiController,
                label: 'UPI ID',
                hintText: 'Enter UPI ID',
              ),
              const SizedBox(height: 16),
              // Bank Account Number Field
              _buildTextField(
                controller: _accountNumberController,
                label: 'Bank Account Number',
                hintText: 'Enter account number',
              ),
              const SizedBox(height: 16),
              // IFSC Code Field
              _buildTextField(
                controller: _ifscController,
                label: 'IFSC Code',
                hintText: 'Enter IFSC code',
              ),
              const SizedBox(height: 16),
              // Account Holder Name Field
              _buildTextField(
                controller: _accountHolderController,
                label: 'Account Holder Name',
                hintText: 'Enter account holder name',
              ),
              const SizedBox(height: 24),
              // Save/Edit Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1B6FF5), // Purple button color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _saveBankDetails, // Call the save function
                  child: Text(
                    _isDataSaved
                        ? 'Edit Details'
                        : 'Save Details', // Toggle button text
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Important Notes Section with off-white background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, // Off-white background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Important Notes:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNoteItem(
                      text:
                          'Double check all details before saving to ensure successful payout.',
                    ),
                    const SizedBox(height: 8),
                    _buildNoteItem(
                      text:
                          'Account holder name should match your bank records exactly.',
                    ),
                    const SizedBox(height: 8),
                    _buildNoteItem(
                      text:
                          'IFSC code can be found on your bank cheque or online banking.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? exampleText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14), // Changed from 16 to 14
          cursorColor: Colors.black,
          cursorWidth: 0.9,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14, // Changed from 16 to 14
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        if (exampleText != null) ...[
          const SizedBox(height: 4),
          Text(
            exampleText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }

  // Helper method to build note items with bullet points
  Widget _buildNoteItem({required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.circle,
            size: 8,
            color: Color(0xFF1B6FF5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(const PayoutDetailsPage());
}
