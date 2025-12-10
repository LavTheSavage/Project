import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kPrimary = Color(0xFF1E88E5);
const Color kAccent = Color(0xFFFFC107);
const Color kBackground = Color(0xFFF5F7FA);
const Color kTextDark = Color(0xFF263238);
const Color kSecondary = Color(0xFF90CAF9);

class LoginPage extends StatefulWidget {
  final SupabaseClient client;

  const LoginPage({super.key, required this.client});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _fullNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRegPassword = true;
  bool _obscureRegConfirm = true;
  bool _rememberMe = false;

  int _selectedTab = 0;

  // ---------------- LOGIN HANDLER ----------------
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await widget.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (_regPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords don't match"),
          backgroundColor: kAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Sign up user with Supabase Auth
      final response = await widget.client.auth.signUp(
        email: _regEmailController.text.trim(),
        password: _regPasswordController.text.trim(),
        data: {"full_name": _fullNameController.text.trim()},
      );

      final user = response.user;

      if (user != null) {
        // 2️⃣ Upsert into 'users' table
        try {
          await widget.client.from('users').upsert({
            'id': user.id, // must match Auth UID
            'email': user.email,
            'full_name': _fullNameController.text.trim(),
          }, onConflict: 'id'); // avoids duplicates
        } catch (e) {
          print("DB insert/upsert error: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Account created but failed to save user info in DB: ${e.toString()}",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        // 3️⃣ Notify user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account created. Verify your email!")),
        );

        setState(() => _selectedTab = 0); // switch to login tab
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------- TOP TABS ----------------
  Widget _buildTopTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedTab == 0
                    ? Colors.white
                    : kSecondary.withOpacity(.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 0
                        ? kPrimary
                        : kTextDark.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedTab == 1
                    ? Colors.white
                    : kSecondary.withOpacity(.2),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 1
                        ? kPrimary
                        : kTextDark.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- INPUT STYLE ----------------
  InputDecoration _inputStyle({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: kTextDark.withOpacity(.8)),
      prefixIcon: Icon(icon, color: kPrimary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kSecondary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kSecondary),
      ),
    );
  }

  // ---------------- SOCIAL BUTTON ----------------
  Widget _socialButton(String asset, String text) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: kSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, height: 20),
            const SizedBox(width: 12),
            Text(text, style: TextStyle(color: kTextDark)),
          ],
        ),
      ),
    );
  }

  // ---------------- LOGIN FORM ----------------
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome Back",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Sign in to continue",
            style: TextStyle(color: kTextDark.withOpacity(.6)),
          ),
          const SizedBox(height: 24),

          // Email
          TextFormField(
            controller: _emailController,
            validator: (v) => (v == null || v.isEmpty) ? "Enter email" : null,
            decoration: _inputStyle(
              label: "Your Email",
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (v) =>
                (v == null || v.isEmpty) ? "Enter password" : null,
            decoration: _inputStyle(label: "Password", icon: Icons.lock_outline)
                .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: kPrimary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                activeColor: kPrimary,
                onChanged: (v) => setState(() => _rememberMe = v!),
              ),
              Text("Remember me", style: TextStyle(color: kTextDark)),
            ],
          ),

          const SizedBox(height: 14),

          // Login Button
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Sign In",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("OR", style: TextStyle(color: kTextDark)),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 20),
          _socialButton("assets/icons/google.png", "Login with Google"),
          const SizedBox(height: 14),
          _socialButton("assets/icons/facebook.png", "Login with Facebook"),
        ],
      ),
    );
  }

  // ---------------- REGISTER FORM ----------------
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let’s Get Started",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Create a new account",
            style: TextStyle(color: kTextDark.withOpacity(.6)),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _fullNameController,
            validator: (v) =>
                (v == null || v.isEmpty) ? "Enter your name" : null,
            decoration: _inputStyle(
              label: "Full Name",
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _regEmailController,
            validator: (v) => (v == null || v.isEmpty) ? "Enter email" : null,
            decoration: _inputStyle(
              label: "Your Email",
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            validator: (v) =>
                (v == null || v.length < 6) ? "Min 6 characters" : null,
            decoration: _inputStyle(label: "Password", icon: Icons.lock_outline)
                .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRegPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: kPrimary,
                    ),
                    onPressed: () => setState(
                      () => _obscureRegPassword = !_obscureRegPassword,
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureRegConfirm,
            validator: (v) =>
                (v == null || v.isEmpty) ? "Confirm password" : null,
            decoration:
                _inputStyle(
                  label: "Password Again",
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRegConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: kPrimary,
                    ),
                    onPressed: () => setState(
                      () => _obscureRegConfirm = !_obscureRegConfirm,
                    ),
                  ),
                ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text("OR", style: TextStyle(color: kTextDark)),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 20),
          _socialButton("assets/icons/google.png", "Sign Up with Google"),
          const SizedBox(height: 14),
          _socialButton("assets/icons/facebook.png", "Sign Up with Facebook"),
        ],
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: MediaQuery.of(context).size.width < 500
                ? double.infinity
                : 450,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTopTabs(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _selectedTab == 0
                        ? _buildLoginForm()
                        : _buildRegisterForm(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
