import 'package:flutter/material.dart';
import 'package:project/pages/admin_app.dart';
import 'package:project/pages/user_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project/helper/admin.dart';
import 'package:project/pages/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return LoginPage(client: Supabase.instance.client);
    }

    return FutureBuilder<bool>(
      future: isCurrentUserAdmin(), // DB CHECK
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.data == true) {
          return const AdminApp(); // 🔥 ADMIN ONLY
        }

        return const UserApp(); // 👤 NORMAL USERS
      },
    );
  }
}
