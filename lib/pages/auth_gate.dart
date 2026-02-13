import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'user_app.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // ❌ Not logged in
        if (session == null) {
          return LoginPage(client: Supabase.instance.client);
        }

        // ✅ Logged in → fetch role
        return FutureBuilder<Map<String, dynamic>>(
          future: supabase
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .single(),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data!['role'];

            // 🔐 ADMIN → ADMIN ONLY UI
            if (role == 'admin') {
              return const AdminDashboardPage();
            }

            // 🧑 USER → USER UI
            return const UserApp();
          },
        );
      },
    );
  }
}
