import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  final ValueNotifier<bool> darkMode = ValueNotifier(false);
  final TextEditingController _searchController = TextEditingController();

  List users = [];
  List items = [];
  int _selectedTab = 0;
  String _searchQuery = '';

  static const List<String> _tabTitles = [
    'Overview',
    'Users',
    'Items',
    'Banned Users',
    'Flagged Items',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

    if (mounted) {
      setState(() => loading = false);
    }
  }

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
  Color get muted => text.withValues(alpha: 0.6);
  Color get primary => const Color(0xFF1E88E5);
  Color get danger => Colors.redAccent;
  Color get warn => Colors.orange;

  List<Map<String, dynamic>> get _filteredUsers {
    final q = _searchQuery.trim().toLowerCase();
    final all = List<Map<String, dynamic>>.from(users);
    if (q.isEmpty) return all;
    return all.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredItems {
    final q = _searchQuery.trim().toLowerCase();
    final all = List<Map<String, dynamic>>.from(items);
    if (q.isEmpty) return all;
    return all.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final location = (item['location'] ?? '').toString().toLowerCase();
      return name.contains(q) || location.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkMode,
      builder: (_, __, ___) {
        return Scaffold(
          backgroundColor: bg,
          drawer: _drawer(),
          appBar: AppBar(
            title: Text(_tabTitles[_selectedTab]),
            backgroundColor: primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_selectedTab >= 1 && _selectedTab <= 4) _searchBox(),
                    Expanded(child: _selectedView()),
                  ],
                ),
        );
      },
    );
  }

  Widget _searchBox() {
    String hint = 'Search';
    if (_selectedTab == 1 || _selectedTab == 3) {
      hint = 'Search users by name or email';
    } else if (_selectedTab == 2 || _selectedTab == 4) {
      hint = 'Search items by name or location';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _selectedView() {
    switch (_selectedTab) {
      case 0:
        return _overview();
      case 1:
        return _users(_filteredUsers);
      case 2:
        return _itemsList(_filteredItems);
      case 3:
        return _bannedUsers(
          _filteredUsers.where((u) => u['is_banned'] == true).toList(),
        );
      case 4:
        return _flaggedItems(
          _filteredItems.where((i) => i['status'] == 'flagged').toList(),
        );
      default:
        return _reports();
    }
  }

  void _selectTab(int index) {
    Navigator.of(context).pop();
    setState(() {
      _selectedTab = index;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _drawerItem({
    required int index,
    required IconData icon,
    required String label,
    int? badge,
  }) {
    return ListTile(
      selected: _selectedTab == index,
      selectedTileColor: primary.withValues(alpha: 0.1),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          if (badge != null && badge > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: danger,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
      title: Text(label),
      onTap: () => _selectTab(index),
    );
  }

  Drawer _drawer() {
    final bannedCount = users.where((u) => u['is_banned'] == true).length;
    final flaggedCount = items.where((i) => i['status'] == 'flagged').length;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(color: primary),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.admin_panel_settings, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${users.length} users  |  ${items.length} items',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(index: 0, icon: Icons.dashboard, label: 'Overview'),
          _drawerItem(index: 1, icon: Icons.people, label: 'Users'),
          _drawerItem(index: 2, icon: Icons.inventory_2, label: 'Items'),
          _drawerItem(
            index: 3,
            icon: Icons.person_off,
            label: 'Banned Users',
            badge: bannedCount,
          ),
          _drawerItem(
            index: 4,
            icon: Icons.flag,
            label: 'Flagged Items',
            badge: flaggedCount,
          ),
          _drawerItem(index: 5, icon: Icons.assessment, label: 'Reports'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: darkMode.value,
            onChanged: (v) => darkMode.value = v,
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Data'),
            onTap: () async {
              Navigator.of(context).pop();
              await _load();
            },
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

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        children: [
          _stat('Users', users.length, () => setState(() => _selectedTab = 1)),
          _stat('Items', items.length, () => setState(() => _selectedTab = 2)),
          _stat(
            'Banned Users',
            banned,
            () => setState(() => _selectedTab = 3),
            danger,
          ),
          _stat(
            'Flagged Items',
            flagged,
            () => setState(() => _selectedTab = 4),
            warn,
          ),
        ],
      ),
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

  Widget _users(List<Map<String, dynamic>> list) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: list.map((u) {
          final warnings = u['warnings'] ?? 0;
          final banned = u['is_banned'] == true;
          final locked = banned || warnings >= 3;

          return _userTile(u, warnings, banned, locked);
        }).toList(),
      ),
    );
  }

  Widget _bannedUsers(List<Map<String, dynamic>> bannedUsers) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: bannedUsers.map((u) {
          return _userTile(u, u['warnings'] ?? 0, true, true);
        }).toList(),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'U';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  Widget _userAvatar(Map u) {
    final name = (u['full_name'] ?? 'User').toString();
    final avatarUrl = (u['avatar_url'] ?? '').toString();
    final validUrl = avatarUrl.startsWith('http');

    return CircleAvatar(
      radius: 22,
      backgroundColor: primary.withValues(alpha: 0.12),
      foregroundImage: validUrl ? NetworkImage(avatarUrl) : null,
      child: Text(
        _initials(name),
        style: TextStyle(color: primary, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _userTile(Map u, int warnings, bool banned, bool locked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _card(),
      child: ListTile(
        leading: _userAvatar(u),
        title: Text(u['full_name'] ?? 'User', style: TextStyle(color: text)),
        subtitle: Text(
          'Warnings: $warnings | ${u['email']}',
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

  Widget _itemsList(List<Map<String, dynamic>> list) {
    return _itemList(list);
  }

  Widget _flaggedItems(List<Map<String, dynamic>> flagged) {
    return _itemList(flagged);
  }

  Widget _itemList(List list) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
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
                if (images.isEmpty)
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: muted.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported, color: muted),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    item['name'] ?? 'Unnamed item',
                    style: TextStyle(fontWeight: FontWeight.bold, color: text),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _reports() {
    final banned = users.where((u) => u['is_banned'] == true).length;
    final flagged = items.where((i) => i['status'] == 'flagged').length;
    final bannedRate = users.isEmpty ? 0 : ((banned / users.length) * 100);
    final flaggedRate = items.isEmpty ? 0 : ((flagged / items.length) * 100);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _reportTile('Total Users', users.length.toString()),
        _reportTile('Total Items', items.length.toString()),
        _reportTile('Banned User Rate', '${bannedRate.toStringAsFixed(1)}%'),
        _reportTile('Flagged Item Rate', '${flaggedRate.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _reportTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _card(),
      child: ListTile(
        title: Text(label, style: TextStyle(color: muted)),
        trailing: Text(
          value,
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  BoxDecoration _card() => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.08)),
        ],
      );
}
