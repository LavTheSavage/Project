import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hamrosaman/widgets/app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/settings_page.dart';
import 'pages/profile_page.dart';
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
        '/profile': (context) => const ProfilePage(),

        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }
}

class MyAppStateNotifier {
  static VoidCallback? refresh;
}

class ItemService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchItems() async {
    try {
      final res = await _client
          .from('items')
          .select('''
          *,
          owner:profiles (
            id,
            full_name,
            avatar_url
          ),
          bookings(
          id,
          status,
          from_date,
          to_date
          )
        ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e, st) {
      debugPrint('❌ fetchItems failed');
      debugPrint(e.toString());
      debugPrint(st.toString());
      rethrow;
    }
  }

  Future<void> addItem(Map<String, dynamic> item) async {
    final user = _client.auth.currentUser!;
    final userProfile = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .single();

    final rawImages = item['images'];

    await _client.from('items').insert({
      ...item,
      'images': rawImages is List
          ? rawImages
          : rawImages is String
          ? [rawImages]
          : [],
      'owner_id': user.id,
      'owner_name': userProfile['full_name'],
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
  String? _avatarUrl;
  RealtimeChannel? _itemsChannel;
  Timer? _reloadTimer;
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;
  int _unreadNotifications = 0;
  String? _currentUserId;
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _notifications = [];
  void _openAddItemPage() async {
    final result = await Navigator.pushNamed(context, '/addItem');

    if (result != null && result is Map<String, dynamic>) {
      await ItemService().addItem(result);
      setState(() {
        _notifications.add({
          'title': "${result['name']} listed",
          'owner': _currentUserId ?? '',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  void _listenToItemChanges() {
    final client = Supabase.instance.client;

    _itemsChannel = client
        .channel('public:items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (payload) async {
            debugPrint('🔄 Items table changed');
            _reloadTimer?.cancel();
            _reloadTimer = Timer(const Duration(milliseconds: 400), _loadItems);
          },
        )
        .subscribe();
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _currentUserId = user.id;
    });

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email, avatar_url')
          .eq('id', user.id)
          .single();

      setState(() {
        _userName = data['full_name'];
        _userEmail = data['email'];
        _avatarUrl = data['avatar_url'];
      });
    } catch (e) {
      setState(() {
        _userName = user.userMetadata?['full_name'] ?? 'User';
        _userEmail = user.email;
        _avatarUrl = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
      _fetchUnreadCount();
    });

    MyAppStateNotifier.refresh = _fetchUnreadCount;
  }

  @override
  void dispose() {
    _itemsChannel?.unsubscribe();
    _reloadTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  Future<void> _fetchUnreadCount() async {
    final uid = currentUserId;
    if (uid == null) return;

    final res = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('handled', false);

    setState(() => _unreadNotifications = res.length);
  }

  Future<void> _loadItems() async {
    try {
      final data = await ItemService().fetchItems();
      setState(() {
        _items = data;
      });
    } catch (e, st) {
      debugPrint('❌ Failed to load items');
      debugPrint(e.toString());
      debugPrint(st.toString());
    } finally {
      // ✅ ALWAYS stop loading
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final id = _items[index]['id'];
    if (id == null) return;
    await supabase
        .from('items')
        .delete()
        .eq('id', id)
        .eq('owner_id', _currentUserId ?? '');

    setState(() => _items.removeAt(index));
  }

  Future<void> _updateItem(int index, Map<String, dynamic> updated) async {
    final id = _items[index]['id'];

    final Map<String, dynamic> payload = {};

    void addIfChanged(String key) {
      if (updated.containsKey(key)) {
        payload[key] = updated[key];
      }
    }

    addIfChanged('name');
    addIfChanged('price');
    addIfChanged('category');
    addIfChanged('condition');
    addIfChanged('location');
    addIfChanged('description');
    addIfChanged('status');
    addIfChanged('favorite');

    if (updated.containsKey('images')) {
      final raw = updated['images'];

      if (raw is List && raw.isNotEmpty) {
        payload['images'] = raw;
      } else if (raw is String && raw.isNotEmpty) {
        payload['images'] = [raw]; // normalize
      }
    }

    if (payload.isEmpty) return;

    await supabase.from('items').update(payload).eq('id', id);

    setState(() {
      _items[index] = {..._items[index], ...payload};
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      if (_items.isEmpty) {
        setState(() => _loading = true);
        _loadItems();
      }
      _listenToItemChanges();
    } else {
      _itemsChannel?.unsubscribe();
      _itemsChannel = null;
    }
  }

  void _openProfilePage() {
    Navigator.pushNamed(context, '/profile');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Samyog Rai ko Project',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [],
      ),
      drawer: AppDrawer(
        userName: _userName,
        email: _userEmail,
        avatarUrl: _avatarUrl,
        onLogout: _logout,
        onProfileTap: _openProfilePage,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotifications > 99
                            ? '99+'
                            : '$_unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notification',
          ),
        ],
      ),

      body: _loading && _selectedIndex == 0
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
          ? SearchPage(
              items: _items,
              categories: appCategories,
              onUpdate: _updateItem,
              onDelete: _deleteItem,
              currentUser: currentUserId,
            )
          : const NotificationsPage(),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemPage,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
