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
    users = await supabase.from('profiles').select().order('created_at');
    items = await supabase.from('items').select().order('created_at');
    setState(() => loading = false);
  }

  String fmt(dynamic d) => DateFormat('MMM dd, yyyy').format(DateTime.parse(d));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tab,
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
              children: [
                _overviewTab(),
                _usersTab(),
                _itemsTab(),
                _broadcastTab(),
              ],
            ),
    );
  }

  // ====================== OVERVIEW ======================

  Widget _overviewTab() {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _statCard('Total Users', users.length, Icons.people),
        _statCard('Total Items', items.length, Icons.inventory),
        _statCard(
          'Banned Users',
          users.where((u) => u['is_banned'] == true).length,
          Icons.block,
        ),
        _statCard(
          'Flagged Items',
          items.where((i) => i['status'] == 'flagged').length,
          Icons.flag,
        ),
      ],
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Container(
      decoration: _card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  // ====================== USERS ======================

  Widget _usersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: u['avatar_url'] != null
                  ? NetworkImage(u['avatar_url'])
                  : null,
              child: u['avatar_url'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(u['full_name'] ?? 'User'),
            subtitle: Text(u['email'] ?? ''),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'ban') {
                  await supabase
                      .from('profiles')
                      .update({'is_banned': true})
                      .eq('id', u['id']);
                }
                if (v == 'unban') {
                  await supabase
                      .from('profiles')
                      .update({'is_banned': false})
                      .eq('id', u['id']);
                }
                _load();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: u['is_banned'] ? 'unban' : 'ban',
                  child: Text(u['is_banned'] ? 'Unban user' : 'Ban user'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================== ITEMS ======================

  Widget _itemsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final images = item['images'] as List?;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: _card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images != null && images.isNotEmpty)
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'By ${item['owner_name']} • ${fmt(item['created_at'])}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
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

  Widget _broadcastTab() {
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
              'Broadcast Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Send to all users'),
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

  // ====================== UI ======================

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.05)),
    ],
  );
}
