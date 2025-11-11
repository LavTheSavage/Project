import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationPermission = true;
  bool _cameraPermission = false;

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@hamrosaman.com',
      query: 'subject=Support%20Request&body=Hello%20Hamro%20Saman%20Team,',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        final launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched != true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email client')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open email client: $e')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/+9779812345678?text=Hello%20Hamro%20Saman%20Team!',
    );
    try {
      if (await canLaunchUrl(whatsappUri)) {
        final launched = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched != true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open WhatsApp: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '🔔 Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            activeThumbColor: const Color(0xFF1E88E5),
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '🔐 Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Location Access'),
            value: _locationPermission,
            activeThumbColor: const Color(0xFF1E88E5),
            onChanged: (val) => setState(() => _locationPermission = val),
          ),
          SwitchListTile(
            title: const Text('Camera Access'),
            value: _cameraPermission,
            activeThumbColor: const Color(0xFF1E88E5),
            onChanged: (val) => setState(() => _cameraPermission = val),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '🆘 Help & Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email, color: Color(0xFF1E88E5)),
            title: const Text('Email Support'),
            onTap: _launchEmail,
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF1E88E5)),
            title: const Text('Chat on WhatsApp'),
            onTap: _launchWhatsApp,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '🎨 Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkModeEnabled,
            activeThumbColor: const Color(0xFF1E88E5),
            onChanged: (val) {
              setState(() => _darkModeEnabled = val);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val ? 'Dark mode enabled' : 'Light mode enabled',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '© 2025 Hamro Saman • All rights reserved',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
