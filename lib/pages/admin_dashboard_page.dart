import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;

  static const bg = Color(0xFFF5F7FA);
  static const primary = Color(0xFF1E88E5);

  bool loading = true;
  List users = [];
  List items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    users = await supabase.from('profiles').select();
    items = await supabase.from('items').select();
    setState(() => loading = false);
  }

  String fmt(dynamic d) =>
      d == null ? '—' : DateFormat('MMM dd, yyyy').format(DateTime.parse(d));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statsGrid(),
                const SizedBox(height: 24),
                _sectionTitle('Users'),
                ...users.map(_userTile),
                const SizedBox(height: 24),
                _sectionTitle('Items'),
                ...items.map(_itemTile),
              ],
            ),
    );
  }

  // ===================== STATS =====================

  Widget _statsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _stat('Users', users.length, Icons.people),
        _stat('Items', items.length, Icons.inventory),
        _stat(
          'Flagged',
          items.where((i) => i['status'] == 'flagged').length,
          Icons.flag,
        ),
        _stat(
          'Banned',
          users.where((u) => u['is_banned'] == true).length,
          Icons.block,
        ),
      ],
    );
  }

  Widget _stat(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // ===================== USERS =====================

  Widget _userTile(dynamic u) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(u['full_name'] ?? 'User'),
        subtitle: Text(u['email'] ?? '—'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'ban') {
              await supabase
                  .from('profiles')
                  .update({'is_banned': true})
                  .eq('id', u['id']);
            }
            if (v == 'warn') {
              await supabase.from('notifications').insert({
                'user_id': u['id'],
                'title': 'Admin warning',
                'body': 'Please follow platform rules',
              });
            }
            _load();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'warn', child: Text('Send warning')),
            PopupMenuItem(value: 'ban', child: Text('Ban user')),
          ],
        ),
      ),
    );
  }

  // ===================== ITEMS =====================

  Widget _itemTile(dynamic i) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const Icon(Icons.inventory_2),
        title: Text(i['name'] ?? 'Item'),
        subtitle: Text('Created ${fmt(i['created_at'])}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'flag') {
              await supabase
                  .from('items')
                  .update({'status': 'flagged'})
                  .eq('id', i['id']);
            }
            if (v == 'delete') {
              await supabase.from('items').delete().eq('id', i['id']);
            }
            _load();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'flag', child: Text('Flag item')),
            PopupMenuItem(value: 'delete', child: Text('Delete item')),
          ],
        ),
      ),
    );
  }

  // ===================== UI HELPERS =====================

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        t,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
