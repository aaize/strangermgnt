import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneOtpWidget extends StatefulWidget {
  const PhoneOtpWidget({Key? key}) : super(key: key);

  @override
  _PhoneOtpWidgetState createState() => _PhoneOtpWidgetState();
}

class _PhoneOtpWidgetState extends State<PhoneOtpWidget> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _otpSent = false;
  bool _isPhoneVerified = false;

  void _sendOtp() async {
    final phoneNumber = '+91${_phoneController.text.trim()}'; // example with +91 country code

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() {
          _isPhoneVerified = true;
          _otpSent = false;
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: ${e.message}')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent!')));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (_verificationId != null && otp.length == 6) {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      try {
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() {
          _isPhoneVerified = true;
          _otpSent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number verified!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    helperText: '* Required',
                    prefixText: '+91 ',
                    suffixIcon: _isPhoneVerified
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _sendOtp();
                  }
                },
                child: const Text('Send OTP'),
              ),
            ],
          ),
          if (_otpSent) ...[
            const SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                helperText: '* Required',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('Verify OTP'),
            ),
          ],
        ],
      ),
    );
  }
}
