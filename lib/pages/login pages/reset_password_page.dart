import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

const Color kPrimary = Color(0xFF1E88E5);
const Color kAccent = Color(0xFFFFC107);
const Color kBackground = Color(0xFFF5F7FA);
const Color kTextDark = Color(0xFF263238);
const Color kSecondary = Color(0xFF90CAF9);

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _reset() async {
    if (_passCtrl.text.length < 6) {
      _showSnack("Password must be at least 6 characters");
      return;
    }

    if (_passCtrl.text != _confirmCtrl.text) {
      _showSnack("Passwords do not match");
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _showSnack("Session expired. Please try again.");
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passCtrl.text.trim()),
      );

      if (!mounted) return;

      _showSnack("Password updated successfully");
      Navigator.pushReplacementNamed(context, '/login');
    } on AuthException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: kTextDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kSecondary),
      ),
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
        title: const Text("Set New Password"),
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kTextDark,
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
              const Icon(Icons.lock_reset, size: 48, color: kPrimary),
              const SizedBox(height: 16),
              const Text(
                "Create a new password",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: _inputStyle("New Password"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: _inputStyle("Confirm Password"),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Update Password",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
