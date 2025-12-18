import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerifyPage extends StatefulWidget {
  final String email;

  const OtpVerifyPage({super.key, required this.email});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  final _otpController = TextEditingController();
  bool _loading = false;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (_secondsLeft <= 0) return false;
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _secondsLeft--);
      return true;
    });
  }

  Future<void> _resendOtp() async {
    await Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: widget.email,
    );
    setState(() => _secondsLeft = 60);
    _startTimer();
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _otpController.text.trim(),
        type: OtpType.email,
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'is_verified': true})
            .eq('id', user.id);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("OTP sent to ${widget.email}"),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              child: const Text("Verify"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _secondsLeft > 0 ? null : _resendOtp,
              child: Text(
                _secondsLeft > 0
                    ? "Resend OTP in $_secondsLeft sec"
                    : "Resend OTP",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
