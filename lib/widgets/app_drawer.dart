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
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF263238), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(40),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl!)
                              : null,
                          backgroundColor: const Color(0xFF90CAF9),
                          child: avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName ?? 'Loading...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onProfileTap,
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: Color(0xFF1E88E5)),
                  title: const Text('Home'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.list_alt, color: Color(0xFF1E88E5)),
                  title: const Text('My Listings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/myListings');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shopping_cart,
                    color: Color(0xFF1E88E5),
                  ),
                  title: const Text('My Rentals'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/myRentals');
                  },
                ),
                const Divider(thickness: 1),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black54),
                  title: const Text('Settings'),
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.black54),
                  title: const Text('About'),
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
              ],
            ),
          ),

          // Logout Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
