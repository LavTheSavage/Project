import 'package:flutter/material.dart';
import 'package:project/pages/admin_dashboard_page.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AdminDashboardPage(),
    );
  }
}
