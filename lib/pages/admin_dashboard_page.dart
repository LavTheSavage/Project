import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tab;

  bool loading = true;
  final ValueNotifier<bool> darkMode = ValueNotifier(false);

  List users = [];
  List items = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    darkMode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    users = await supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);

    items = await supabase
        .from('items')
        .select()
        .neq('status', 'deleted')
        .order('created_at', ascending: false);

    setState(() => loading = false);
  }

  String fmt(String? d) =>
      d == null ? '—' : DateFormat('MMM dd, yyyy').format(DateTime.parse(d));

  List<String> parseImages(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        if (raw.startsWith('http')) return [raw];
      }
    }
    return [];
  }

  Color get bg =>
      darkMode.value ? const Color(0xFF121212) : const Color(0xFFF4F6F9);
  Color get card => darkMode.value ? const Color(0xFF1E1E1E) : Colors.white;
  Color get text => darkMode.value ? Colors.white : const Color(0xFF263238);
  Color get muted => text.withOpacity(0.6);
  Color get primary => const Color(0xFF1E88E5);
  Color get danger => Colors.redAccent;
  Color get warn => Colors.orange;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkMode,
      builder: (_, __, ___) {
        return Scaffold(
          backgroundColor: bg,
          drawer: _drawer(),
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: primary,
            bottom: TabBar(
              controller: _tab,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Users'),
                Tab(text: 'Items'),
                Tab(text: 'Banned Users'),
                Tab(text: 'Flagged Items'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  children: [
                    _overview(),
                    _users(),
                    _items(),
                    _bannedUsers(),
                    _flaggedItems(),
                    _reports(),
                  ],
                ),
        );
      },
    );
  }

  Drawer _drawer() {
    return Drawer(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text(
              'Admin Panel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: darkMode.value,
            onChanged: (v) => darkMode.value = v,
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async => supabase.auth.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _overview() {
    final banned = users.where((u) => u['is_banned'] == true).length;
    final flagged = items.where((i) => i['status'] == 'flagged').length;

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      children: [
        _stat('Users', users.length, () => _tab.animateTo(1)),
        _stat('Items', items.length, () => _tab.animateTo(2)),
        _stat('Banned Users', banned, () => _tab.animateTo(3), danger),
        _stat('Flagged Items', flagged, () => _tab.animateTo(4), warn),
      ],
    );
  }

  Widget _stat(String label, int value, VoidCallback onTap, [Color? color]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: _card(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color ?? text,
              ),
            ),
            Text(label, style: TextStyle(color: muted)),
          ],
        ),
      ),
    );
  }

  Widget _users() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: users.map((u) {
        final warnings = u['warnings'] ?? 0;
        final banned = u['is_banned'] == true;
        final locked = banned || warnings >= 3;

        return _userTile(u, warnings, banned, locked);
      }).toList(),
    );
  }

  Widget _bannedUsers() {
    final bannedUsers = users.where((u) => u['is_banned'] == true).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: bannedUsers.map((u) {
        return _userTile(u, u['warnings'] ?? 0, true, true);
      }).toList(),
    );
  }

  Widget _userTile(Map u, int warnings, bool banned, bool locked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _card(),
      child: ListTile(
        title: Text(u['full_name'] ?? 'User', style: TextStyle(color: text)),
        subtitle: Text(
          'Warnings: $warnings • ${u['email']}',
          style: TextStyle(color: muted),
        ),
        trailing: locked
            ? IconButton(
                icon: const Icon(Icons.lock_open, color: Colors.green),
                onPressed: () async {
                  await supabase
                      .from('profiles')
                      .update({'is_banned': false, 'warnings': 0})
                      .eq('id', u['id']);
                  _load();
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.warning, color: warn),
                    onPressed: () async {
                      final newWarn = warnings + 1;
                      await supabase
                          .from('profiles')
                          .update({
                            'warnings': newWarn,
                            'is_banned': newWarn >= 3,
                          })
                          .eq('id', u['id']);
                      _load();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.block, color: danger),
                    onPressed: () async {
                      await supabase
                          .from('profiles')
                          .update({'is_banned': true})
                          .eq('id', u['id']);
                      _load();
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _items() {
    return _itemList(items);
  }

  Widget _flaggedItems() {
    final flagged = items.where((i) => i['status'] == 'flagged').toList();
    return _itemList(flagged);
  }

  Widget _itemList(List list) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: list.map((item) {
        final images = parseImages(item['images']);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty)
                Image.network(
                  images.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  item['name'],
                  style: TextStyle(fontWeight: FontWeight.bold, color: text),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _reports() {
    return const Center(child: Text('Reports coming soon'));
  }

  BoxDecoration _card() => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.08)),
    ],
  );
}
