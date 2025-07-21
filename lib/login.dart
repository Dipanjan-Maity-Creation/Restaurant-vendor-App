import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification_screen.dart';
import 'owner_details.dart';
import 'home_screen.dart';
import 'restaurant_details.dart';
import 'document_upload_page.dart';
import 'errormessage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isOtpLoading = false;
  bool _isGoogleLoading = false;
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _signInWithGoogle({bool isSignIn = false}) async {
    setState(() => _isGoogleLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return; // User cancelled the sign-in
      }
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential;
      try {
        userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' && isSignIn) {
// Email is linked to another account, try to link it
          final existingUser = await _findUserByEmail(googleUser.email);
          if (existingUser != null) {
            await FirebaseAuth.instance.signOut();
            await googleSignIn.signOut();
            userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
          } else {
            throw FirebaseAuthException(
              code: 'email-already-in-use',
              message: 'This email is already registered with another account.',
            );
          }
        } else {
          rethrow;
        }
      }
      final User? user = userCredential.user;
      if (user != null) {
        QuerySnapshot existingUsers = await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .where('email', isEqualTo: user.email)
            .get();
        if (isSignIn && existingUsers.docs.isEmpty) {
// Email not registered, redirect to sign-up flow
          await FirebaseAuth.instance.signOut();
          await googleSignIn.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'This email is not registered. Redirecting to sign-up.')),
            );
// Re-authenticate for sign-up
            final newGoogleUser = await googleSignIn.signIn();
            if (newGoogleUser == null) {
              setState(() => _isGoogleLoading = false);
              return;
            }
            final newGoogleAuth = await newGoogleUser.authentication;
            final newCredential = GoogleAuthProvider.credential(
              accessToken: newGoogleAuth.accessToken,
              idToken: newGoogleAuth.idToken,
            );
            userCredential =
            await FirebaseAuth.instance.signInWithCredential(newCredential);
            if (userCredential.user == null) {
              throw Exception('Sign-up failed: No user data');
            }
            return _handleGoogleSignUp(userCredential.user!,
                newGoogleUser.email ?? '', newGoogleUser.displayName ?? '');
          }
        }
        String restaurantId = existingUsers.docs.isNotEmpty
            ? existingUsers.docs.first['restaurantId'] ??
            'rest_${user.uid}_${DateTime.now().millisecondsSinceEpoch}'
            : 'rest_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user.uid)
            .set({
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'uid': user.uid,
          'restaurantId': restaurantId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('UserRestaurantMapping')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'restaurantId': restaurantId,
        }, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('Restaurants')
            .doc(restaurantId)
            .set({
          'restaurantId': restaurantId,
          'name': user.displayName ?? 'Unnamed Restaurant',
          'authorizedUids': FieldValue.arrayUnion([user.uid]),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _navigateBasedOnUserData(user.uid, restaurantId);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-in failed: No user data')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignUp(
      User user, String email, String displayName) async {
    try {
      final restaurantId =
          'rest_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(user.uid);
      DocumentReference mappingDocRef = FirebaseFirestore.instance
          .collection('UserRestaurantMapping')
          .doc(user.uid);
      DocumentReference restaurantDocRef = FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId);

      batch.set(
          userDocRef,
          {
            'email': email,
            'name': displayName,
            'uid': user.uid,
            'restaurantId': restaurantId,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
      batch.set(
          mappingDocRef,
          {
            'uid': user.uid,
            'restaurantId': restaurantId,
          },
          SetOptions(merge: true));
      batch.set(
          restaurantDocRef,
          {
            'restaurantId': restaurantId,
            'name': displayName.isNotEmpty ? displayName : 'Unnamed Restaurant',
            'authorizedUids': FieldValue.arrayUnion([user.uid]),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed up with Google')),
        );
        await _navigateBasedOnUserData(user.uid, restaurantId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    }
  }

  Future<User?> _findUserByEmail(String? email) async {
    if (email == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .where('email', isEqualTo: email)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final uid = snapshot.docs.first['uid'];
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        return user;
      }
      return null;
    }
    return null;
  }

  Future<void> _sendOTP({bool isSignIn = false}) async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }
    setState(() => _isOtpLoading = true);
    String phoneNumber = '+91${_phoneController.text.trim()}';
    try {
      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .where('contact', isEqualTo: phoneNumber)
          .get();
      if (isSignIn && existingUsers.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This phone number is not registered. Please sign up.')),
          );
        }
        setState(() => _isOtpLoading = false);
        return;
      }
      if (!isSignIn && existingUsers.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This phone number is already registered. Please sign in.')),
          );
        }
        setState(() => _isOtpLoading = false);
        return;
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _handlePhoneCredential(credential, phoneNumber);
          setState(() => _isOtpLoading = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isOtpLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(getFriendlyErrorMessage(e))),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isOtpLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
                onVerified: (credential, phone) async {
                  await _handlePhoneCredential(credential, phone);
                },
              ),
            ),
          ).then((value) {
            setState(() => _isOtpLoading = false);
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isOtpLoading = false);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
      setState(() => _isOtpLoading = false);
    }
  }

  Future<void> _handlePhoneCredential(
      PhoneAuthCredential credential, String phoneNumber) async {
    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('User authentication failed.');
      }
      final uid = user.uid;
      QuerySnapshot existingUsers = await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .where('contact', isEqualTo: phoneNumber)
          .get();
      if (existingUsers.docs.isNotEmpty &&
          existingUsers.docs.first['uid'] != uid) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'This phone number is already registered. Please sign in.')),
          );
        }
        return;
      }
      String restaurantId = existingUsers.docs.isNotEmpty
          ? existingUsers.docs.first['restaurantId'] ??
          'rest_${uid}_${DateTime.now().millisecondsSinceEpoch}'
          : 'rest_${uid}_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(uid)
          .set({
        'contact': phoneNumber,
        'uid': uid,
        'restaurantId': restaurantId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('UserRestaurantMapping')
          .doc(uid)
          .set({
        'uid': uid,
        'restaurantId': restaurantId,
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .set({
        'restaurantId': restaurantId,
        'name': 'Unnamed Restaurant',
        'authorizedUids': FieldValue.arrayUnion([uid]),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _navigateBasedOnUserData(uid, restaurantId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getFriendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _navigateBasedOnUserData(String uid, String restaurantId) async {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ownerDoc = await FirebaseFirestore.instance
        .collection('Restaurants')
        .doc(restaurantId)
        .collection('OwnerDetails')
        .doc(uid)
        .get();
    final restaurantDoc = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(user.uid)
        .collection('RestaurantDetails')
        .doc(uid)
        .get();
    final documentsDoc = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(user.uid)
        .collection('UploadedDocuments')
        .doc(uid)
        .get();
    bool hasOwnerDetails = ownerDoc.exists;
    bool hasRestaurantDetails = restaurantDoc.exists;
    bool hasUploadedDocuments = documentsDoc.exists;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed in')),
      );
      Widget destination;
      if (hasOwnerDetails && hasRestaurantDetails && hasUploadedDocuments) {
        destination = const HomeWidget();
      } else if (hasOwnerDetails && hasRestaurantDetails) {
        destination = const DocumentUploadScreen();
      } else if (hasOwnerDetails) {
        destination = const CreateProfileScreen();
      } else {
        destination = Ownership(
          prefilledEmail: user.email ?? '',
          prefilledPhone: user.phoneNumber?.replaceFirst('+91', '') ?? '',
          isPhoneVerified: user.phoneNumber != null,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => destination),
                (Route<dynamic> route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Rectangle2.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.4),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Join as a Partner',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.poppins(fontSize: 16),
                          cursorColor: Colors.black,
                          cursorWidth: 0.8,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Phone number',
                            labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
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
                            errorText: _phoneController.text.isNotEmpty &&
                                _phoneController.text.length != 10
                                ? 'Enter a valid 10-digit phone number'
                                : null,
                          ),
                          onTap: () async {
                            ClipboardData? data =
                            await Clipboard.getData('text/plain');
                            if (data != null &&
                                data.text != null &&
                                RegExp(r'^\d{10}$').hasMatch(data.text!)) {
                              _phoneController.text = data.text!;
                              FocusScope.of(context).unfocus();
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isOtpLoading || _isGoogleLoading
                                ? null
                                : () => _sendOTP(isSignIn: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B6FF5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: GoogleFonts.poppins(fontSize: 16),
                            ),
                            child: _isOtpLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                                : Text('Sign Up with OTP',
                                style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isOtpLoading || _isGoogleLoading
                                ? null
                                : () => _sendOTP(isSignIn: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B6FF5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: GoogleFonts.poppins(fontSize: 16),
                            ),
                            child: Text('Sign In with OTP',
                                style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isOtpLoading || _isGoogleLoading
                                ? null
                                : () => _signInWithGoogle(isSignIn: false),
                            icon: _isGoogleLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black),
                              ),
                            )
                                : Image.asset(
                              'assets/images/GoogleSVG.png',
                              width: 24,
                              height: 24,
                            ),
                            label: Text(
                              _isGoogleLoading
                                  ? 'Signing up...'
                                  : 'Sign Up with Google',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isOtpLoading || _isGoogleLoading
                                ? null
                                : () => _signInWithGoogle(isSignIn: true),
                            icon: _isGoogleLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black),
                              ),
                            )
                                : Image.asset(
                              'assets/images/GoogleSVG.png',
                              width: 24,
                              height: 24,
                            ),
                            label: Text(
                              _isGoogleLoading
                                  ? 'Signing in...'
                                  : 'Sign In with Google',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 24,
            right: 24,
            child: Center(
              child: Text(
                'By continuing, you agree to the Terms and Conditions\nand Privacy Policy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
