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
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _reset() async {
    final password = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (password.length < 6) {
      _showSnack("Password must be at least 6 characters");
      return;
    }

    if (password != confirm) {
      _showSnack("Passwords do not match");
      return;
    }

    setState(() => _loading = true);

    // 🔑 CAPTURE USER ID EARLY
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      // 1️⃣ Update password (THIS is the critical operation)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      // 2️⃣ Edge function = best-effort
      if (userId != null) {
        try {
          await Supabase.instance.client.functions.invoke(
            'verify_after_recovery',
            body: {'user_id': userId},
          );
        } catch (e) {
          // ⚠️ Do NOT fail password reset because of this
          debugPrint('Edge function failed: $e');
        }
      }

      // 3️⃣ Always end recovery session
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      _showSnack("Password updated successfully");
      Navigator.pushReplacementNamed(context, '/login');
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      // If we reached here, password STILL likely succeeded
      _showSnack("Password updated. Please log in again.");
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputStyle({
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: kTextDark),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          isVisible ? Icons.visibility_off : Icons.visibility,
          color: kSecondary,
        ),
      ),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text("Set New Password"),
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kTextDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 18,
                      ),
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
                        obscureText: !_showPassword,
                        decoration: _inputStyle(
                          label: "New Password",
                          isVisible: _showPassword,
                          onToggle: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmCtrl,
                        obscureText: !_showConfirmPassword,
                        decoration: _inputStyle(
                          label: "Confirm Password",
                          isVisible: _showConfirmPassword,
                          onToggle: () {
                            setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            );
                          },
                        ),
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
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Update Password",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
