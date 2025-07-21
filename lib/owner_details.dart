import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'restaurant_details.dart';
import 'errormessage.dart';
import 'otp_verification_screen.dart';

class Ownership extends StatefulWidget {
  final String? prefilledEmail;
  final String? prefilledPhone;
  final bool isPhoneVerified;

  const Ownership({
    super.key,
    this.prefilledEmail,
    this.prefilledPhone,
    this.isPhoneVerified = false,
  });

  @override
  _OwnershipState createState() => _OwnershipState();
}

class _OwnershipState extends State<Ownership> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late bool phoneVerified;
  String? _phoneVerificationId;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController(
      text: widget.prefilledPhone?.replaceFirst('+91', '') ?? '',
    );
    _emailController = TextEditingController(text: widget.prefilledEmail);
    phoneVerified = widget.isPhoneVerified;
    _loadOwnerDetails();
    _phoneController.addListener(() {
      if (_phoneController.text.trim().length != 10 && phoneVerified && !widget.isPhoneVerified) {
        setState(() {
          phoneVerified = false;
          _phoneVerificationId = null;
        });
      }
      setState(() {});
    });
    _emailController.addListener(() => setState(() {}));
    _fullNameController.addListener(() => setState(() {}));
  }

  Future<void> _loadOwnerDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
        });
        return;
      }
      DocumentSnapshot userDoc = await _firestore.collection('RestaurantUsers').doc(user.uid).get();
      String? restaurantId = userDoc.exists ? userDoc['restaurantId'] : null;
      if (restaurantId == null) {
        setState(() {
          _errorMessage = 'Restaurant not found';
        });
        return;
      }
      DocumentSnapshot doc = await _firestore
          .collection('Restaurants')
          .doc(restaurantId)
          .collection('OwnerDetails')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _fullNameController.text = doc['fullName']?.toString() ?? '';
          _emailController.text = doc['email']?.toString() ?? widget.prefilledEmail ?? '';
          String? phone = doc['phone']?.toString();
          _phoneController.text = phone != null
              ? phone.startsWith('+91')
              ? phone.replaceFirst('+91', '')
              : phone
              : widget.prefilledPhone?.replaceFirst('+91', '') ?? '';
          phoneVerified = user.phoneNumber != null;
        });
      } else {
        setState(() {
          _fullNameController.text = _fullNameController.text.isEmpty ? '' : _fullNameController.text;
          _emailController.text = _emailController.text.isEmpty ? widget.prefilledEmail ?? '' : _emailController.text;
          _phoneController.text = _phoneController.text.isEmpty ? widget.prefilledPhone?.replaceFirst('+91', '') ?? '' : _phoneController.text;
          phoneVerified = widget.isPhoneVerified;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = getFriendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveOwnerDetails() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }
    try {
      setState(() => _isSaving = true);
      String phoneNumber = '+91${_phoneController.text.trim()}';
      String email = _emailController.text.trim();
      DocumentSnapshot userDoc = await _firestore.collection('RestaurantUsers').doc(user.uid).get();
      String restaurantId = userDoc['restaurantId'] ?? 'rest_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      QuerySnapshot existingEmail = await _firestore
          .collection('RestaurantUsers')
          .where('email', isEqualTo: email)
          .get();
      QuerySnapshot existingPhone = await _firestore
          .collection('RestaurantUsers')
          .where('contact', isEqualTo: phoneNumber)
          .get();
      if (existingEmail.docs.isNotEmpty && existingEmail.docs.first['uid'] != user.uid) {
        throw Exception('This email is already in use.');
      }
      if (existingPhone.docs.isNotEmpty && existingPhone.docs.first['uid'] != user.uid) {
        throw Exception('This phone number is already in use.');
      }
      WriteBatch batch = _firestore.batch();
      DocumentReference ownerDocRef = _firestore
          .collection('Restaurants')
          .doc(restaurantId)
          .collection('OwnerDetails')
          .doc(user.uid);
      DocumentReference userDocRef = _firestore.collection('RestaurantUsers').doc(user.uid);
      final ownerData = {
        'fullName': _fullNameController.text.trim(),
        'email': email,
        'phone': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final userData = {
        'name': _fullNameController.text.trim(),
        'email': email,
        'contact': phoneNumber,
        'uid': user.uid,
        'restaurantId': restaurantId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(ownerDocRef, ownerData, SetOptions(merge: true));
      batch.set(userDocRef, userData, SetOptions(merge: true));
      batch.set(
        _firestore.collection('Restaurants').doc(restaurantId),
        {
          'restaurantId': restaurantId,
          'name': _fullNameController.text.trim(),
          'authorizedUids': FieldValue.arrayUnion([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        _firestore.collection('UserRestaurantMapping').doc(user.uid),
        {
          'uid': user.uid,
          'restaurantId': restaurantId,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateProfileScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _sendPhoneOTP() async {
    String phoneNumber = '+91${_phoneController.text.trim()}';
    if (phoneNumber.length != 13) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid 10-digit phone number')),
        );
      }
      return;
    }
    QuerySnapshot existingUsers = await _firestore
        .collection('RestaurantUsers')
        .where('contact', isEqualTo: phoneNumber)
        .get();
    if (existingUsers.docs.isNotEmpty && existingUsers.docs.first['uid'] != _auth.currentUser?.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This phone number is already in use. Please use a different number or sign in.')),
        );
      }
      return;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(getFriendlyErrorMessage(e))),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _phoneVerificationId = verificationId;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationPage(
                  verificationId: verificationId,
                  phoneNumber: phoneNumber,
                  onVerified: (credential, phone) async {
                    await _linkPhoneCredential(credential);
                  },
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _phoneVerificationId = verificationId;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
        if (mounted) {
          setState(() {
            phoneVerified = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  bool get _isFormComplete {
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return _fullNameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length == 10 &&
        phoneVerified &&
        _emailController.text.trim().isNotEmpty &&
        emailPattern.hasMatch(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text(
          'Owner Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Go Back?'),
                content: const Text('Your progress will be saved. Continue?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await _saveOwnerDetails();
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(getFriendlyErrorMessage(e))),
                          );
                        }
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isFormComplete && !_isSaving && !_isLoading
                ? () async {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email')),
                );
                return;
              }
              await _saveOwnerDetails();
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B6FF5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              'Next',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Owner Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  hintText: "Enter owner's full name",
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 14,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  errorText: _fullNameController.text.trim().isEmpty ? 'Full name is required' : null,
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                cursorColor: Colors.black,
                cursorWidth: 0.9,
              ),
              const SizedBox(height: 20),
              Text(
                'Email Address',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter business email address',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  errorText: _emailController.text.trim().isNotEmpty &&
                      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())
                      ? 'Enter a valid email'
                      : null,
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                keyboardType: TextInputType.emailAddress,
                cursorColor: Colors.black,
                cursorWidth: 0.9,
              ),
              const SizedBox(height: 20),
              Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.02,
                      vertical: MediaQuery.of(context).size.height * 0.015,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/India.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+91',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      readOnly: phoneVerified,
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffix: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: phoneVerified
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/images/check-circle.svg',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    phoneVerified = false;
                                    _phoneVerificationId = null;
                                  });
                                },
                                child: Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          )
                              : GestureDetector(
                            onTap: _phoneController.text.trim().length == 10 ? _sendPhoneOTP : null,
                            child: Text(
                              'Verify',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _phoneController.text.trim().length == 10 ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        errorText: _phoneController.text.trim().isNotEmpty && _phoneController.text.trim().length != 10
                            ? 'Enter a valid 10-digit phone number'
                            : null,
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      cursorColor: Colors.black,
                      cursorWidth: 0.9,
                      onTap: () async {
                        ClipboardData? data = await Clipboard.getData('text/plain');
                        if (data != null &&
                            data.text != null &&
                            RegExp(r'^\d{10}$').hasMatch(data.text!) &&
                            !phoneVerified) {
                          _phoneController.text = data.text!;
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Restaurant's Primary Contact Number",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Customers, delivery partners, and Yaammy may call on this number for order support.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}