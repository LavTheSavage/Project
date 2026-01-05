import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../otp_verify_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

const Color kPrimary = Color(0xFF1E88E5);
const Color kAccent = Color(0xFFFFC107);
const Color kBackground = Color(0xFFF5F7FA);
const Color kTextDark = Color(0xFF263238);
const Color kSecondary = Color(0xFF90CAF9);

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;

  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 1) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack("Please enter your email");
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      if (!mounted) return;

      _showSnack(isResend ? "OTP resent" : "OTP sent");
      setState(() => _otpSent = true);
      _startResendTimer();

      if (!isResend) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerifyPage(email: email, otpType: OtpType.recovery),
          ),
        );
      }
    } on AuthException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  InputDecoration _inputStyle() {
    return InputDecoration(
      labelText: "Email",
      filled: true,
      fillColor: Colors.white,
      prefixIcon: const Icon(Icons.email_outlined, color: kPrimary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kTextDark,
        title: const Text("Forgot Password"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 18),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: kPrimary),
              const SizedBox(height: 16),
              const Text(
                "Reset your password",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We’ll send a verification code to your email",
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextDark),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputStyle(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _sendOtp(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Send Code",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),

              if (_otpSent) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _canResend && !_loading
                      ? () => _sendOtp(isResend: true)
                      : null,
                  child: Text(
                    _canResend ? "Resend Code" : "Resend in $_resendTimer s",
                    style: const TextStyle(color: kAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
