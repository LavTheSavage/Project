import 'package:flutter/material.dart';
import 'pages/my_listings_page.dart';
import 'pages/my_rentals_page.dart';
import 'pages/settings_page.dart';
import 'pages/browse_page.dart';
import 'pages/search_page.dart';
import 'pages/item_form_page.dart';
// ignore: unused_import
import 'pages/item_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/about_us_page.dart';

const List<String> appCategories = [
  'All',
  'Electronics',
  'Appliances',
  'Tools',
];

void main() => runApp(const MyAppRoot());

class MyAppRoot extends StatelessWidget {
  const MyAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/': (context) => const MyApp(),
        '/addItem': (context) => ItemFormPage(categories: appCategories),
        '/editItem': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ItemFormPage(categories: appCategories, existingItem: args);
        },
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutUsPage(),
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String _currentUser = 'me';
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _items = [
    {
      'name': 'Drill',
      'price': '1200',
      'category': 'Tools',
      'description': 'Heavy duty drill.',
      'image': null,
      'owner': 'me',
    },
    {
      'name': 'Camera',
      'price': '5000',
      'category': 'Electronics',
      'description': 'DSLR camera.',
      'image': null,
      'owner': 'Rajesh Hamal',
    },
  ];

  void _openAddItemPage() async {
    final result = await Navigator.pushNamed(context, '/addItem');
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        result['owner'] = _currentUser;
        _items.add(result);
      });
    }
  }

  void _deleteItem(int index) {
    setState(() {
      if (index >= 0 && index < _items.length) _items.removeAt(index);
    });
  }

  void _updateItem(int index, Map<String, dynamic> updated) {
    setState(() {
      updated['owner'] = _items[index]['owner'] ?? _currentUser;
      _items[index] = updated;
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('User Profile'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Name: Test User'),
            Text('📧 Email: test@example.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      BrowsePage(
        items: _items,
        categories: appCategories,
        onDelete: _deleteItem,
        onUpdate: _updateItem,
        currentUser: _currentUser,
      ),
      SearchPage(
        items: _items,
        categories: appCategories,
        onUpdate: _updateItem,
        currentUser: _currentUser,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Samyog Rai ko Project"),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF263238), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Color(0xFF90CAF9),
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'test@example.com',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showProfileDialog,
                        icon: const Icon(
                          Icons.panorama_fish_eye,
                          color: Colors.white70,
                        ),
                        tooltip: 'Edit profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.home, color: Color(0xFF1E88E5)),
                    title: const Text('Home'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: const Icon(
                      Icons.list_alt,
                      color: Color(0xFF1E88E5),
                    ),
                    title: const Text('My Listings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyListingsPage(
                            items: _items,
                            currentUser: _currentUser,
                            onDelete: _deleteItem,
                            onUpdate: _updateItem,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: const Icon(
                      Icons.shopping_cart,
                      color: Color(0xFF1E88E5),
                    ),
                    title: const Text('My Rentals'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyRentalsPage(rentals: _items),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Divider(thickness: 1),
                  ),

                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.settings, color: Colors.black54),
                    title: const Text('Settings'),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.info, color: Colors.black54),
                    title: const Text('About'),
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
            ),

            SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        },
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_search),
            label: 'Search',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemPage,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
