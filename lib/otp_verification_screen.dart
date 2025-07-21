import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'errormessage.dart';
import 'dart:developer' as developer;

class OtpVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final Function(PhoneAuthCredential, String)? onVerified;

  const OtpVerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.onVerified,
  });

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String _errorMessage = '';
  late Timer _timer;
  int _secondsRemaining = 30;
  double _errorOpacity = 1.0;
  Timer? _errorTimer;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
    developer.log(
        'OtpVerificationPage initialized with verificationId: $_verificationId, phoneNumber: ${widget.phoneNumber}',
        name: 'OtpVerification');
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
        _errorOpacity = 1.0;
        for (var controller in _controllers) {
          controller.clear();
        }
      });
      _startTimer();
      developer.log('Timer restarted', name: 'OtpVerification');
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _errorOpacity = 1.0;
    });

    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorOpacity = 0.0;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _errorMessage = '';
            });
          }
        });
      }
    });
    developer.log('Error message shown: $message', name: 'OtpVerification');
  }

  @override
  void dispose() {
    _timer.cancel();
    _errorTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
    developer.log('OtpVerificationPage disposed', name: 'OtpVerification');
  }

  void _nextField(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      _showErrorMessage('Verification ID is missing.');
      developer.log('Verification ID is null',
          name: 'OtpVerification', error: 'Missing verificationId');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _errorOpacity = 1.0;
    });

    String otpCode = _controllers.map((controller) => controller.text).join();
    if (otpCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otpCode)) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Enter a valid 6-digit OTP');
      developer.log('Invalid OTP input: $otpCode', name: 'OtpVerification');
      return;
    }

    try {
      developer.log(
          'Verifying OTP: $otpCode with verificationId: $_verificationId',
          name: 'OtpVerification');
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      if (widget.onVerified != null) {
        await widget.onVerified!(credential, widget.phoneNumber);
        if (mounted) {
          developer.log('OTP verification successful, popping page',
              name: 'OtpVerification');
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Verification handler not provided');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage(getFriendlyErrorMessage(e));
      developer.log(
          'FirebaseAuthException during OTP verification: ${e.code} - ${e.message}',
          name: 'OtpVerification',
          error: e);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage(getFriendlyErrorMessage(e));
      developer.log('Error during OTP verification: $e',
          name: 'OtpVerification', error: e);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _errorOpacity = 1.0;
    });

    try {
      developer.log('Resending OTP for phoneNumber: ${widget.phoneNumber}',
          name: 'OtpVerification');
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          developer.log('Auto-verification completed during resend',
              name: 'OtpVerification');
          if (widget.onVerified != null) {
            await widget.onVerified!(credential, widget.phoneNumber);
            if (mounted) {
              Navigator.pop(context, true);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showErrorMessage(getFriendlyErrorMessage(e));
            developer.log(
                'Verification failed during resend: ${e.code} - ${e.message}',
                name: 'OtpVerification',
                error: e);
          }
        },
        codeSent: (String newVerificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = newVerificationId;
              _restartTimer();
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP resent successfully')),
            );
            developer.log('OTP resent, new verificationId: $newVerificationId',
                name: 'OtpVerification');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
            developer.log(
                'Auto-retrieval timeout, verificationId: $verificationId',
                name: 'OtpVerification');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage(getFriendlyErrorMessage(e));
        developer.log('Error resending OTP: $e',
            name: 'OtpVerification', error: e);
      }
    }
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
        onChanged: (value) => _nextField(value, index),
        onTap: () async {
          ClipboardData? data = await Clipboard.getData('text/plain');
          if (data != null &&
              data.text != null &&
              data.text!.length == 6 &&
              RegExp(r'^\d{6}$').hasMatch(data.text!)) {
            for (int i = 0; i < 6; i++) {
              _controllers[i].text = data.text![i];
            }
            FocusScope.of(context).unfocus();
            _verifyOtp();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0.0,
        elevation: 0,
        leadingWidth: 40,
        title: Text(
          'OTP Verification',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Please enter the verification code sent to',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.phoneNumber,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOTPField(index)),
                ),
                const SizedBox(height: 30),
                _secondsRemaining > 0
                    ? Text(
                        'Resend OTP in ($_secondsRemaining) seconds',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      )
                    : GestureDetector(
                        onTap: _isLoading ? null : _resendOtp,
                        child: Text(
                          'Resend OTP',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _isLoading
                                ? Colors.grey
                                : const Color(0xFF1B6FF5),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  AnimatedOpacity(
                    opacity: _errorOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFF1B6FF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? LoadingAnimationWidget.progressiveDots(
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: LoadingAnimationWidget.progressiveDots(
                  color: const Color(0xFF1B6FF5),
                  size: 50,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
