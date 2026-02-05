import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String? userName;
  final String? email;
  final String? avatarUrl;
  final VoidCallback onLogout;
  final VoidCallback onProfileTap;

  const AppDrawer({
    super.key,
    this.userName,
    this.email,
    this.avatarUrl,
    required this.onLogout,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(child: Text('Your existing drawer UI here'));
  }
}
