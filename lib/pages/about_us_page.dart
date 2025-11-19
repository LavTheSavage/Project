import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void _launchURL(BuildContext context, String url) async {
  final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
  try {
    if (await canLaunchUrl(uri)) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
    }
  }
}

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Center(
            child: Text(
              'Samyog Rai ko Project',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Your trusted local marketplace',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 24),

          // 👥 Team Section
          const Text(
            '👥 Our Team',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'I am a passionate developer from Nepal, '
            'building a platform to simplify local renting of tools and electronics.',
          ),
          const SizedBox(height: 12),
          const Card(
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFF1E88E5),
                child: Text('SR', style: TextStyle(color: Colors.white)),
              ),
              title: Text('Samyog Rai'),
              subtitle: Text('Founder & Lead Developer'),
            ),
          ),
          const Card(
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFF1E88E5),
                child: Text('SR', style: TextStyle(color: Colors.white)),
              ),
              title: Text('Samyog Rai'),
              subtitle: Text('UI/UX Designer'),
            ),
          ),
          const SizedBox(height: 24),

          // 📞 Contact Info
          const Text(
            '📞 Contact Us',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.email, color: Color(0xFF1E88E5)),
            title: const Text('samyograi0ff@gmail.com'),
            onTap: () => _launchURL(context, 'mailto:samyograi0ff@gmail.com'),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Color(0xFF1E88E5)),
            title: const Text('+977-9841161810'),
            onTap: () => _launchURL(context, 'tel:+9779841161810'),
          ),
          const ListTile(
            leading: Icon(Icons.location_on, color: Color(0xFF1E88E5)),
            title: Text('Kathmandu, Nepal'),
          ),
          const SizedBox(height: 24),

          // 🌐 Social Media Links
          const Text(
            '🌐 Follow Us',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.facebook, color: Color(0xFF1E88E5)),
            title: const Text('Facebook'),
            onTap: () =>
                _launchURL(context, 'http://facebook.com/samyog.rai.805339/'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF1E88E5)),
            title: const Text('Instagram'),
            onTap: () => _launchURL(
              context,
              'https://www.instagram.com/lel_samyog_rai/',
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.alternate_email,
              color: Color(0xFF1E88E5),
            ),
            title: const Text('Twitter'),
            onTap: () =>
                _launchURL(context, 'https://twitter.com/xainatwitterta'),
          ),
          const SizedBox(height: 24),

          // 📄 Legal Info
          const Text(
            '📄 Legal Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.policy, color: Color(0xFF1E88E5)),
            title: const Text('Privacy Policy'),
            onTap: () => _launchURL(context, 'https://hamrosaman.com/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Color(0xFF1E88E5)),
            title: const Text('Terms & Conditions'),
            onTap: () => _launchURL(context, 'https://hamrosaman.com/terms'),
          ),
          const SizedBox(height: 24),

          // 🔢 App Version
          const Divider(),
          const Center(
            child: Text(
              'App Version 1.0.0 (Build 1)',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '© 2025 Hamro Saman. All rights reserved.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
