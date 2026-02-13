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

  List users = [];
  List items = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    users = await supabase.from('profiles').select();
    items = await supabase.from('items').select();
    setState(() => loading = false);
  }

  String fmt(String d) => DateFormat('MMM dd, yyyy').format(DateTime.parse(d));

  // ====================== UI COLORS ======================

  static const primary = Color(0xFF1E88E5);
  static const accent = Color(0xFFFFC107);
  static const bg = Color(0xFFF5F7FA);
  static const dark = Color(0xFF263238);
  static const softBlue = Color(0xFF90CAF9);

  // ====================== BUILD ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: primary,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: accent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.inventory), text: 'Items'),
            Tab(icon: Icon(Icons.campaign), text: 'Broadcast'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [_overview(), _users(), _items(), _broadcast()],
            ),
    );
  }

  // ====================== OVERVIEW ======================

  Widget _overview() {
    final banned = users.where((u) => u['is_banned'] == true).length;
    final flagged = items.where((i) => i['status'] == 'flagged').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _stat('Users', users.length, Icons.people),
          _stat('Items', items.length, Icons.inventory),
          _stat('Banned', banned, Icons.block),
          _stat('Flagged', flagged, Icons.flag),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon) {
    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: softBlue,
            child: Icon(icon, color: primary),
          ),
          const SizedBox(height: 16),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // ====================== USERS ======================

  Widget _users() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: softBlue,
              backgroundImage: u['avatar_url'] != null
                  ? NetworkImage(u['avatar_url'])
                  : null,
              child: u['avatar_url'] == null
                  ? const Icon(Icons.person, color: primary)
                  : null,
            ),
            title: Text(u['full_name'] ?? 'User'),
            subtitle: Text(u['email'] ?? ''),
            trailing: PopupMenuButton(
              onSelected: (v) async {
                await supabase
                    .from('profiles')
                    .update({'is_banned': v == 'ban'})
                    .eq('id', u['id']);
                _load();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: u['is_banned'] ? 'unban' : 'ban',
                  child: Text(u['is_banned'] ? 'Unban' : 'Ban'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================== ITEMS ======================

  Widget _items() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];

        final rawImages = item['images'];
        final List<String> images = rawImages is List
            ? List<String>.from(rawImages)
            : rawImages is String
            ? [rawImages]
            : [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    images.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 120,
                  color: softBlue,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dark,
                            ),
                          ),
                          Text(
                            'By ${item['owner_name']} • ${fmt(item['created_at'])}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
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
                              .delete()
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

  // ====================== BROADCAST ======================

  Widget _broadcast() {
    final title = TextEditingController();
    final body = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: _card(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Broadcast to all users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: body,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: dark,
              ),
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              onPressed: () async {
                for (final u in users) {
                  await supabase.from('notifications').insert({
                    'user_id': u['id'],
                    'title': title.text,
                    'body': body.text,
                  });
                }
                title.clear();
                body.clear();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Broadcast sent')));
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====================== CARD ======================

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.06)),
    ],
  );
}
