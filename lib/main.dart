import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/my_listings_page.dart';
import 'pages/my_rentals_page.dart';
import 'pages/settings_page.dart';
import 'pages/search_page.dart';
import 'pages/item_form_page.dart';
// ignore: unused_import
import 'pages/item_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/about_us_page.dart';
import 'pages/notification_page.dart';
import 'pages/start_up_page.dart';

final supabase = Supabase.instance.client;

const List<String> appCategories = [
  'All',
  'Electronics',
  'Appliances',
  'Tools',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://orfcnqyvcxphfgfxsvrm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9yZmNucXl2Y3hwaGZnZnhzdnJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNzQ3MTUsImV4cCI6MjA4MDk1MDcxNX0.gox9lzfQEF-TOyWMLdZtw85iIUE1__Du88kDCZ43Ap4',
  );

  runApp(const MyAppRoot());
}

class MyAppRoot extends StatelessWidget {
  const MyAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: const Color(0xFFFFC107)),
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Color(0xFFFFFFFF),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFC107),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF263238)),
          bodyMedium: TextStyle(color: Color(0xFF263238)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF90CAF9),
          disabledColor: Colors.grey.shade300,
          selectedColor: const Color(0xFF1E88E5),
          secondarySelectedColor: const Color(0xFF1E88E5),
          labelStyle: const TextStyle(color: Color(0xFF263238)),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/startUp',
      routes: {
        '/startUp': (context) => const Startup(),
        '/login': (context) => LoginPage(client: supabase),
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

        '/notifications': (context) => NotificationsPage(notifications: []),
      },
    );
  }
}

class ItemService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final res = await _client
        .from('items')
        .select('''
          *,
          owner:profiles (
            full_name,
            avatar_url
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> addItem(Map<String, dynamic> item) async {
    final user = _client.auth.currentUser!;
    await _client.from('items').insert({
      ...item,
      'owner_id': user.id,
      'owner_name': user.email,
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _userEmail;
  String? _userName;

  final String _currentUser = 'me';
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _notifications = [];
  void _openAddItemPage() async {
    final result = await Navigator.pushNamed(context, '/addItem');

    if (result != null && result is Map<String, dynamic>) {
      await ItemService().addItem(result);
      await _loadItems();
      setState(() {
        _notifications.add({
          'title': "${result['name']} listed",
          'owner': _currentUser,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('users')
          .select('full_name, email')
          .eq('id', user.id)
          .single();

      setState(() {
        _userName = data['full_name'] ?? 'User';
        _userEmail = data['email'] ?? user.email;
      });
    } catch (e) {
      debugPrint('Failed to load user profile: $e');

      // fallback (still works)
      setState(() {
        _userName = user.userMetadata?['full_name'] ?? 'User';
        _userEmail = user.email;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadItems();
  }

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  Future<void> _loadItems() async {
    final data = await ItemService().fetchItems();
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Future<void> _deleteItem(int index) async {
    final id = _items[index]['id'];

    await supabase.from('items').delete().eq('id', id);

    setState(() => _items.removeAt(index));
  }

  Future<void> _updateItem(int index, Map<String, dynamic> updated) async {
    final old = Map<String, dynamic>.from(_items[index]);
    final id = _items[index]['id'];

    // Remove relational object before sending to Supabase
    final payload = Map<String, dynamic>.from(updated)..remove('owner');

    await supabase.from('items').update(payload).eq('id', id);

    setState(() {
      // Keep the existing owner object intact
      updated['owner'] = _items[index]['owner'];

      _items[index] = updated;

      final oldStatus = (old['status'] ?? '').toString();
      final newStatus = (updated['status'] ?? '').toString();

      if (oldStatus != newStatus) {
        _notifications.add({
          'title': "${updated['name'] ?? 'Item'} status: $newStatus",
          'owner': updated['owner']?['full_name'] ?? 'Unknown',
          'timestamp': DateTime.now(),
        });
      }
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Name: ${_userName ?? "Loading..."}'),
            const SizedBox(height: 6),
            Text('📧 Email: ${_userEmail ?? ""}'),
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
            onPressed: () async {
              // Sign out from Supabase
              await Supabase.instance.client.auth.signOut();

              // Close the dialog first
              if (context.mounted) Navigator.pop(context);

              // Navigate to login page and remove all previous routes
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(client: supabase),
                  ),
                  (route) => false,
                );
              }
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
      SearchPage(
        items: _items,
        categories: appCategories,
        onUpdate: _updateItem,
        onDelete: _deleteItem,
        currentUser: _currentUser,
      ),
      NotificationsPage(notifications: _notifications),
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
                            Text(
                              _userName ?? 'Loading...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _userEmail ?? '',
                              style: const TextStyle(
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
                        tooltip: 'View profile',
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
      // Use the loading-aware body below; removed duplicated `body` here.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemPage,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
