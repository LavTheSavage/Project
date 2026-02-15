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
    _tab = TabController(length: 4, vsync: this);
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

  // ================= HELPERS =================

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

  // ================= THEME =================

  Color get bg =>
      darkMode.value ? const Color(0xFF121212) : const Color(0xFFF4F6F9);
  Color get card => darkMode.value ? const Color(0xFF1E1E1E) : Colors.white;
  Color get text => darkMode.value ? Colors.white : const Color(0xFF263238);
  Color get muted => text.withOpacity(0.6);
  Color get primary => const Color(0xFF1E88E5);
  Color get danger => Colors.redAccent;
  Color get warn => Colors.orange;

  // ================= BUILD =================

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
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.people), text: 'Users'),
                Tab(icon: Icon(Icons.inventory), text: 'Items'),
                Tab(icon: Icon(Icons.report), text: 'Reports'),
              ],
            ),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  children: [_overview(), _users(), _items(), _reports()],
                ),
        );
      },
    );
  }

  // ================= DRAWER =================

  Drawer _drawer() {
    return Drawer(
      child: SafeArea(
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
      ),
    );
  }

  // ================= OVERVIEW =================

  Widget _overview() {
    final banned = users.where((u) => u['is_banned'] == true).length;
    final flagged = items.where((i) => i['status'] == 'flagged').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _stat('Users', users.length),
            _stat('Items', items.length),
            _stat('Banned', banned, danger),
            _stat('Flagged Items', flagged, warn),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, int value, [Color? color]) {
    return Container(
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
    );
  }

  // ================= USERS =================

  Widget _users() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        final warnings = u['warnings'] ?? 0;
        final banned = u['is_banned'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _card(),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: u['avatar_url'] != null
                  ? NetworkImage(u['avatar_url'])
                  : null,
              child: u['avatar_url'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              u['full_name'] ?? 'User',
              style: TextStyle(color: text),
            ),
            subtitle: Text(
              'Warnings: $warnings • ${u['email'] ?? ''}',
              style: TextStyle(color: muted),
            ),
            trailing: Row(
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
                        .update({'is_banned': !banned})
                        .eq('id', u['id']);
                    _load();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= ITEMS =================

  Widget _items() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: text,
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      onSelected: (v) async {
                        if (v == 'flag') {
                          await supabase
                              .from('items')
                              .update({'status': 'flagged'})
                              .eq('id', item['id']);
                        }
                        if (v == 'delete') {
                          await supabase
                              .from('items')
                              .update({'status': 'deleted'})
                              .eq('id', item['id']);
                        }
                        _load();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'flag', child: Text('Flag')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= REPORTS =================

  Widget _reports() {
    return const Center(
      child: Text(
        'User reports will appear here',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  BoxDecoration _card() => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.08)),
    ],
  );
}
