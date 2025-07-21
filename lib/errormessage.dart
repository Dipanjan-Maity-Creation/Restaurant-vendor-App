// lib/utils/firebase_utils.dart
import 'package:firebase_auth/firebase_auth.dart';

String getFriendlyErrorMessage(dynamic error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid credentials. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
  return 'An unexpected error occurred.';
}