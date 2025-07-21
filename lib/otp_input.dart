// lib/widgets/otp_input_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'errormessage.dart'; // or 'errormessage.dart'
import 'package:firebase_auth/firebase_auth.dart';

class OTPInputWidget extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final Future<bool> Function(String) onVerify;
  final bool isBottomSheet;
  final VoidCallback? onClose;

  const OTPInputWidget({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerify,
    this.isBottomSheet = false,
    this.onClose,
  });

  @override
  _OTPInputWidgetState createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late Timer _timer;
  int _secondsRemaining = 30;
  bool _isOtpComplete = false;
  String _errorMessage = '';
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
    _updateOtpStatus();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && mounted) {
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
    if (mounted) {
      setState(() {
        _secondsRemaining = 30;
        _errorMessage = '';
        for (var controller in _controllers) {
          controller.clear();
        }
        _isOtpComplete = false;
      });
      _startTimer();
    }
  }

  void _updateOtpStatus() {
    bool complete = _controllers.every((ctrl) => ctrl.text.length == 1);
    if (mounted) {
      setState(() {
        _isOtpComplete = complete;
      });
    }
  }

  Future<void> _resendOtp() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() {
              _errorMessage = getFriendlyErrorMessage(e);
            });
          }
        },
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _restartTimer();
              _errorMessage = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP resent successfully')),
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = getFriendlyErrorMessage(e);
        });
      }
    }
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
        style: GoogleFonts.poppins(fontSize: 16, height: 1.2),
        textAlign: TextAlign.center,
        cursorColor: Colors.black,
        cursorWidth: 0.9,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        onTap: () async {
          ClipboardData? data = await Clipboard.getData('text/plain');
          if (data != null && data.text != null && data.text!.length == 6 && RegExp(r'^\d{6}$').hasMatch(data.text!)) {
            for (int i = 0; i < 6; i++) {
              _controllers[i].text = data.text![i];
            }
            _updateOtpStatus();
            FocusScope.of(context).unfocus();
            if (_isOtpComplete) {
              _verifyOtp();
            }
          }
        },
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification ID is missing.';
      });
      return;
    }

    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Enter the complete 6-digit OTP';
      });
      return;
    }

    bool verified = await widget.onVerify(otp);
    if (!verified && mounted) {
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    }
    if (mounted) {
      Navigator.of(context).pop(verified);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(12.0))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: widget.isBottomSheet ? MediaQuery.of(context).viewInsets.bottom + 16 : 30,
        ),
        child: Column(
          mainAxisSize: widget.isBottomSheet ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enter verification code',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isBottomSheet)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose ?? () => Navigator.of(context).pop(false),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '6 digit OTP has been sent to ${widget.phoneNumber}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOTPField(index)),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            _secondsRemaining > 0
                ? Text(
              'Resend OTP in ($_secondsRemaining) seconds',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            )
                : GestureDetector(
              onTap: _resendOtp,
              child: Text(
                'Resend OTP',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1B6FF5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isOtpComplete ? _verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6FF5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Verify',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            if (!widget.isBottomSheet) const Spacer(),
          ],
        ),
      ),
    );
  }
}