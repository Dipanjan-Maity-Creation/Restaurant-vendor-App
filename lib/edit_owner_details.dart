import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Added for Timer
import 'settings_screen.dart'; // Import SettingsPage for navigation

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _originalPhoneNumber; // Store the original phone number
  String? _originalEmail; // Store the original email
  bool _phoneVerified = false; // Track if the new phone number is verified
  bool _emailVerified = false; // Track if the new email is verified

  @override
  void initState() {
    super.initState();
    _fetchOwnerDetails();
    _phoneController.addListener(() {
      setState(() {
        if (_phoneController.text.trim() != _originalPhoneNumber) {
          _phoneVerified = false;
        }
      });
    });
    _emailController.addListener(() {
      setState(() {
        if (_emailController.text.trim() != _originalEmail) {
          _emailVerified = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Fetch existing owner details from Firestore
  Future<void> _fetchOwnerDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(uid)
          .collection('OwnerDetails')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _originalPhoneNumber = data['phone']?.replaceFirst('+91', '') ?? '';
          _phoneController.text = _originalPhoneNumber ?? '';
          _originalEmail = data['email'] ?? user.email ?? '';
          _emailController.text = _originalEmail ?? '';
          _phoneVerified = true; // Existing phone number is verified
          _emailVerified = user.emailVerified; // Check if email is verified
        });
      } else {
        setState(() {
          _emailController.text = user.email ?? '';
          _originalEmail = user.email ?? '';
          _emailVerified = user.emailVerified; // Check if email is verified
        });
      }
    }
  }

  // Show OTP verification bottom sheet for phone
  Future<bool?> _showVerificationBottomSheet(
      String identifier, bool isPhone) async {
    if (isPhone && _phoneController.text.trim().length != 10) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return _OTPVerificationSheet(
            identifier: '+91${_phoneController.text.trim()}', isPhone: isPhone);
      },
    );
    return result;
  }

  // Show email verification popup - only called when clicking the icon
  Future<void> _showEmailVerificationPopup() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _emailController.text.trim().isNotEmpty) {
      try {
        // Send verification email without updating immediately
        await user.sendEmailVerification();
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: Text(
                "Verification link sent to ${_emailController.text.trim()}. Please verify your email first. Note: The new email will be updated in Firebase Auth after verification.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BAUHAUSM',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Color(0xFF1B6FF5)),
                  ),
                ),
              ],
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending verification email: $e\nMake sure Email/Password authentication is enabled in Firebase Console.',
            ),
          ),
        );
        return;
      }
    }
  }

  // Save updated owner details to Firestore
  Future<void> _saveOwnerDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final newPhoneNumber = _phoneController.text.trim();
      final newEmail = _emailController.text.trim();

      // Check if phone number has changed
      if (newPhoneNumber != _originalPhoneNumber && newPhoneNumber.isNotEmpty) {
        if (newPhoneNumber.length != 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number must be 10 digits')),
          );
          return;
        }
        final phoneVerified =
            await _showVerificationBottomSheet(newPhoneNumber, true);
        if (phoneVerified == true) {
          setState(() {
            _phoneVerified = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP does not match')),
          );
          return;
        }
      }

      // Save to Firestore regardless of email verification status
      if (_phoneVerified || newPhoneNumber == _originalPhoneNumber) {
        await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(uid)
            .collection('OwnerDetails')
            .doc(uid)
            .set({
          'fullName': _fullNameController.text.trim(),
          'phone': '+91${_phoneController.text.trim()}',
          'email': _emailController.text.trim(),
        }, SetOptions(merge: true));

        // Show message if email changed but not verified
        if (newEmail != _originalEmail && !_emailVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile saved. Please verify your new email to update it in Firebase Auth.',
              ),
            ),
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fullNameController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter full name',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
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
                ),
                cursorColor: Colors.black,
                cursorWidth: 0.9,
              ),
              const SizedBox(height: 20),
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 16.0),
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: SvgPicture.asset(
                        'assets/images/mobile-notch.svg',
                        width: 8,
                        height: 8,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  suffixIcon: _phoneVerified
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 16.0),
                          child: SizedBox(
                            width: 8,
                            height: 8,
                            child: SvgPicture.asset(
                              'assets/images/check-circle.svg',
                              width: 8,
                              height: 8,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : null,
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
                ),
                cursorColor: Colors.black,
                cursorWidth: 0.9,
              ),
              const SizedBox(height: 20),
              const Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 16.0),
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: SvgPicture.asset(
                        'assets/images/Contact.svg',
                        width: 8,
                        height: 8,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: _showEmailVerificationPopup,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 16.0),
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: SvgPicture.asset(
                          _emailVerified
                              ? 'assets/images/check-circle.svg'
                              : 'assets/images/interrogation.svg',
                          width: 8,
                          height: 8,
                          color: Colors.black,
                        ),
                      ),
                    ),
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
                ),
                cursorColor: Colors.black,
                cursorWidth: 0.9,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveOwnerDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6FF5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// OTP Verification Bottom Sheet remains unchanged
class _OTPVerificationSheet extends StatefulWidget {
  final String identifier; // Phone number
  final bool isPhone; // To differentiate between phone and email

  const _OTPVerificationSheet(
      {required this.identifier, required this.isPhone});

  @override
  _OTPVerificationSheetState createState() => _OTPVerificationSheetState();
}

class _OTPVerificationSheetState extends State<_OTPVerificationSheet> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late Timer _timer;
  int _secondsRemaining = 30;
  bool _isOtpComplete = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _updateOtpStatus();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _restartTimer() {
    _timer.cancel();
    setState(() {
      _secondsRemaining = 30;
    });
    _startTimer();
  }

  void _updateOtpStatus() {
    bool complete = _controllers.every((ctrl) => ctrl.text.length == 1);
    setState(() {
      _isOtpComplete = complete;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 40,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        style: const TextStyle(fontSize: 16, height: 1.2),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: Colors.black,
        cursorWidth: 0.9,
        magnifierConfiguration: TextMagnifierConfiguration.disabled,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
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
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
          _updateOtpStatus();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enter verification code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '6 digit OTP has been sent to ${widget.identifier}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildOTPField(index)),
          ),
          const SizedBox(height: 16),
          _secondsRemaining > 0
              ? Text(
                  'Resend OTP in ($_secondsRemaining) seconds',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                )
              : GestureDetector(
                  onTap: _restartTimer,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(fontSize: 14, color: Color(0xFF1B6FF5)),
                  ),
                ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isOtpComplete
                  ? () {
                      // Simulate OTP verification (replace with real logic if needed)
                      Navigator.of(context).pop(true);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6FF5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}