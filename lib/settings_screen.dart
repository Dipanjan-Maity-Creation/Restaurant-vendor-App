import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'errormessage.dart';
import 'otp_verification_screen.dart';
import 'package:flutter/services.dart'; // Add this import

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _isLinkingGoogle = false;
  bool _isLinkingPhone = false;
  String? _userEmail;
  String? _userPhone;
  String? _restaurantId;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userEmail = userDoc['email'] ?? user.email;
            _userPhone = userDoc['contact'] ?? user.phoneNumber;
            _restaurantId = userDoc['restaurantId'];
            _emailController.text = _userEmail ?? '';
            _phoneController.text = _userPhone?.replaceFirst('+91', '') ?? '';
          });
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

  Future<void> _linkGoogleAccount() async {
    setState(() => _isLinkingGoogle = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-signed-in',
          message: 'Please sign in to link a Google account.',
        );
      }
      if (_restaurantId == null) {
        throw Exception(
            'Restaurant ID not found. Please complete your profile setup.');
      }

      bool isGoogleLinked =
      user.providerData.any((info) => info.providerId == 'google.com');
      if (isGoogleLinked) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'A Google account is already linked to this account.')),
          );
        }
        setState(() => _isLinkingGoogle = false);
        return;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLinkingGoogle = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .where('email', isEqualTo: googleUser.email)
          .get();
      if (existingUsers.docs.isNotEmpty &&
          existingUsers.docs.first['uid'] != user.uid) {
        await googleSignIn.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This Google account is already registered with another user.')),
          );
        }
        setState(() => _isLinkingGoogle = false);
        return;
      }

      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        await googleSignIn.signOut();
        if (e.code == 'credential-already-in-use' ||
            e.code == 'account-exists-with-different-credential') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'This Google account is already linked to another user.')),
            );
          }
        } else if (e.code == 'requires-recent-login') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Please sign out and sign in again to link your Google account.')),
            );
          }
        } else {
          throw e;
        }
        setState(() => _isLinkingGoogle = false);
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid);
      DocumentReference restaurantDocRef = FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(_restaurantId);
      DocumentReference ownerDocRef = FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(_restaurantId)
          .collection('OwnerDetails')
          .doc(user.uid);

      batch.set(
        userDocRef,
        {
          'email': googleUser.email,
          'name': googleUser.displayName ?? '',
          'restaurantId': _restaurantId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        restaurantDocRef,
        {
          'authorizedUids': FieldValue.arrayUnion([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        ownerDocRef,
        {
          'email': googleUser.email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google account linked successfully')),
        );
        setState(() {
          _userEmail = googleUser.email;
          _emailController.text = googleUser.email ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLinkingGoogle = false);
      }
    }
  }

  Future<void> _linkPhoneNumber() async {
    final phoneNumber = '+91${_phoneController.text.trim()}';
    if (_phoneController.text.trim().length != 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid 10-digit phone number')),
        );
      }
      return;
    }
    setState(() => _isLinkingPhone = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-signed-in',
          message: 'Please sign in to link a phone number.',
        );
      }
      if (_restaurantId == null) {
        throw Exception(
            'Restaurant ID not found. Please complete your profile setup.');
      }

      bool isPhoneLinked =
      user.providerData.any((info) => info.providerId == 'phone');
      if (isPhoneLinked && _userPhone == phoneNumber) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This phone number is already linked to this account.')),
          );
        }
        setState(() => _isLinkingPhone = false);
        return;
      }

      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .where('contact', isEqualTo: phoneNumber)
          .get();
      if (existingUsers.docs.isNotEmpty &&
          existingUsers.docs.first['uid'] != user.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This phone number is already registered with another user.')),
          );
        }
        setState(() => _isLinkingPhone = false);
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _handlePhoneCredential(user, credential, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(getFriendlyErrorMessage(e))),
            );
          }
          setState(() => _isLinkingPhone = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationPage(
                  verificationId: verificationId,
                  phoneNumber: phoneNumber,
                  onVerified: (credential, phone) async {
                    await _handlePhoneCredential(user, credential, phone);
                  },
                ),
              ),
            ).then((_) {
              setState(() => _isLinkingPhone = false);
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isLinkingPhone = false);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
      setState(() => _isLinkingPhone = false);
    }
  }

  Future<void> _handlePhoneCredential(
      User user, PhoneAuthCredential credential, String phoneNumber) async {
    try {
      await user.linkWithCredential(credential);

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid);
      DocumentReference ownerDocRef = FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(_restaurantId)
          .collection('OwnerDetails')
          .doc(user.uid);

      batch.set(
        userDocRef,
        {
          'contact': phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        ownerDocRef,
        {
          'phone': phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number linked successfully')),
        );
        setState(() {
          _userPhone = phoneNumber;
          _phoneController.text = phoneNumber.replaceFirst('+91', '');
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'account-exists-with-different-credential') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This phone number is already linked to another user. Please sign in with that account.')),
          );
        }
      } else if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Please sign out and sign in again to link your phone number.')),
          );
        }
      } else {
        throw e;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _updateEmail() async {
    String email = _emailController.text.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-signed-in',
          message: 'Please sign in to update your email.',
        );
      }
      if (_restaurantId == null) {
        throw Exception(
            'Restaurant ID not found. Please complete your profile setup.');
      }

      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .where('email', isEqualTo: email)
          .get();
      if (existingUsers.docs.isNotEmpty &&
          existingUsers.docs.first['uid'] != user.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This email is already registered with another account.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await user.updateEmail(email);

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid);
      DocumentReference ownerDocRef = FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(_restaurantId)
          .collection('OwnerDetails')
          .doc(user.uid);

      batch.set(
        userDocRef,
        {
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        ownerDocRef,
        {
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully')),
        );
        setState(() {
          _userEmail = email;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Details',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Phone Number', style: GoogleFonts.poppins()),
                    subtitle: Text(_userPhone ?? 'Not linked',
                        style: GoogleFonts.poppins()),
                    trailing: _userPhone != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  ListTile(
                    title: Text('Email', style: GoogleFonts.poppins()),
                    subtitle: Text(_userEmail ?? 'Not linked',
                        style: GoogleFonts.poppins()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Update Email',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
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
                      errorText: _emailController.text.isNotEmpty &&
                          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(_emailController.text)
                          ? 'Enter a valid email'
                          : null,
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                      _isLoading || _isLinkingGoogle || _isLinkingPhone
                          ? null
                          : _updateEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6FF5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Update Email',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Link Phone Number',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
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
                      errorText: _phoneController.text.isNotEmpty &&
                          _phoneController.text.length != 10
                          ? 'Enter a valid 10-digit phone number'
                          : null,
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                      _isLoading || _isLinkingGoogle || _isLinkingPhone
                          ? null
                          : _linkPhoneNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6FF5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLinkingPhone
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Link Phone Number',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                      _isLoading || _isLinkingGoogle || _isLinkingPhone
                          ? null
                          : _linkGoogleAccount,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide.none,
                      ),
                      child: _isLinkingGoogle
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text('Link Google Account',
                          style: GoogleFonts.poppins(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    title: Text('Sign Out', style: GoogleFonts.poppins()),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                              (Route<dynamic> route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading || _isLinkingGoogle || _isLinkingPhone)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
