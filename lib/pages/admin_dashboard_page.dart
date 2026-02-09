
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color kPrimary = Color(0xFF1E88E5);
  static const Color kAccent = Color(0xFFFFC107);
  static const Color kBackground = Color(0xFFF5F7FA);
  static const Color kDark = Color(0xFF263238);
  static const Color kSecondary = Color(0xFF90CAF9);

  final _supabase = Supabase.instance.client;
  final _userSearchCtrl = TextEditingController();
  final _itemSearchCtrl = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _items = [];

  String _userFilter = 'All';
  String _itemFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    _itemSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_fetchUsers(), _fetchItems()]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchUsers() async {
    final res = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    _users = List<Map<String, dynamic>>.from(res);
  }

  Future<void> _fetchItems() async {
    final res = await _supabase
        .from('items')
        .select('*, owner:profiles(id, full_name, email, avatar_url)')
        .order('created_at', ascending: false);
    _items = List<Map<String, dynamic>>.from(res);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(dynamic raw) {
    final dt = _parseDate(raw);
    if (dt == null) return '—';
    return DateFormat('MMM dd, yyyy').format(dt);
  }

  DateTime? _lastSeen(Map<String, dynamic> u) {
    return _parseDate(u['last_seen']) ??
        _parseDate(u['last_active']) ??
        _parseDate(u['updated_at']);
  }

  bool _isVerified(Map<String, dynamic> u) {
    if (u.containsKey('is_verified')) {
      return u['is_verified'] == true;
    }
    return true;
  }

  bool _isBanned(Map<String, dynamic> u) {
    if (u.containsKey('is_banned')) {
      return u['is_banned'] == true;
    }
    return false;
  }

  String _userStatus(Map<String, dynamic> u) {
    if (_isBanned(u)) return 'Banned';
    if (!_isVerified(u)) return 'Unverified';
    final last = _lastSeen(u);
    if (last == null) return 'Offline';
    final diff = DateTime.now().difference(last);
    return diff.inMinutes <= 15 ? 'Active' : 'Offline';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Offline':
        return Colors.grey;
      case 'Unverified':
        return Colors.orange;
      case 'Banned':
        return Colors.red;
    }
    return Colors.grey;
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _userSearchCtrl.text.trim().toLowerCase();
    return _users.where((u) {
      final status = _userStatus(u);
      if (_userFilter != 'All' && status != _userFilter) return false;
      if (query.isEmpty) return true;
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _itemSearchCtrl.text.trim().toLowerCase();
    return _items.where((i) {
      final status = (i['status'] ?? 'active').toString().toLowerCase();
      if (_itemFilter == 'Flagged' && status != 'flagged') return false;
      if (_itemFilter == 'Pending' && status != 'pending') return false;
      if (_itemFilter == 'Active' && status != 'active') return false;
      if (query.isEmpty) return true;
      final name = (i['name'] ?? '').toString().toLowerCase();
      final owner = (i['owner_name'] ?? i['owner']?['full_name'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(query) || owner.contains(query);
    }).toList();
  }
  Future<void> _warnUser(Map<String, dynamic> user) async {
    final controller = TextEditingController(
      text: 'Please review the community guidelines and update your activity.',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Warning'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final userId = user['id'];
    if (userId == null) return;
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': 'Account warning',
      'body': controller.text.trim(),
      'type': 'admin_warning',
      'handled': false,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Warning sent')));
  }

  Future<void> _warnItemOwner(Map<String, dynamic> item) async {
    final ownerId = item['owner_id'] ?? item['owner']?['id'];
    if (ownerId == null) return;
    await _supabase.from('notifications').insert({
      'user_id': ownerId,
      'title': 'Item warning',
      'body':
          'Your item "${item['name'] ?? 'item'}" was flagged for review. Please check the listing details.',
      'type': 'admin_item_warning',
      'handled': false,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Owner warned')));
  }

  Future<void> _setUserBan(Map<String, dynamic> user, bool banned) async {
    final payload = <String, dynamic>{};
    if (user.containsKey('is_banned')) {
      payload['is_banned'] = banned;
    }
    if (user.containsKey('status')) {
      payload['status'] = banned ? 'banned' : 'active';
    }
    if (payload.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ban fields not configured on profiles')),
      );
      return;
    }
    await _supabase.from('profiles').update(payload).eq('id', user['id']);
    await _fetchUsers();
    if (mounted) setState(() {});
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('This will permanently remove the listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _supabase.from('items').delete().eq('id', item['id']);
    await _fetchItems();
    if (mounted) setState(() {});
  }

  Future<void> _setItemFlag(Map<String, dynamic> item, bool flagged) async {
    if (!item.containsKey('status')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item status field not configured')),
      );
      return;
    }
    await _supabase
        .from('items')
        .update({'status': flagged ? 'flagged' : 'active'})
        .eq('id', item['id']);
    await _fetchItems();
    if (mounted) setState(() {});
  }

  Future<void> _sendBroadcast() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Broadcast Message'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Message to all users',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (controller.text.trim().isEmpty) return;
    final inserts = _users
        .where((u) => u['id'] != null)
        .map(
          (u) => {
            'user_id': u['id'],
            'title': 'Admin announcement',
            'body': controller.text.trim(),
            'type': 'admin_announcement',
            'handled': false,
          },
        )
        .toList();
    if (inserts.isEmpty) return;
    const batchSize = 200;
    for (var i = 0; i < inserts.length; i += batchSize) {
      final batch = inserts.sublist(
        i,
        (i + batchSize).clamp(0, inserts.length),
      );
      await _supabase.from('notifications').insert(batch);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Broadcast sent')));
  }
  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = _userStatus(user);
    final banned = _isBanned(user);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kSecondary,
            backgroundImage: user['avatar_url'] != null
                ? NetworkImage(user['avatar_url'])
                : null,
            child: user['avatar_url'] == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Joined ${_formatDate(user['created_at'])}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                tooltip: 'Warn user',
                onPressed: () => _warnUser(user),
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              ),
              IconButton(
                tooltip: banned ? 'Unban user' : 'Ban user',
                onPressed: () => _setUserBan(user, !banned),
                icon: Icon(
                  banned ? Icons.lock_open : Icons.block,
                  color: banned ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final images = item['images'];
    final thumb = images is List && images.isNotEmpty ? images.first : null;
    final status = (item['status'] ?? 'active').toString().toLowerCase();
    final ownerName = item['owner']?['full_name'] ?? item['owner_name'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumb != null
                ? Image.network(
                    thumb,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 32),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: kSecondary.withOpacity(0.3),
                    child: const Icon(Icons.inventory_2, color: kPrimary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ownerName.isEmpty ? 'Owner: —' : 'Owner: $ownerName',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'flagged'
                            ? Colors.red.withOpacity(0.12)
                            : kPrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: status == 'flagged' ? Colors.red : kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(item['created_at']),
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                tooltip: 'Warn owner',
                onPressed: () => _warnItemOwner(item),
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              ),
              IconButton(
                tooltip: 'Delete item',
                onPressed: () => _deleteItem(item),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
              IconButton(
                tooltip: status == 'flagged' ? 'Unflag item' : 'Flag item',
                onPressed: () => _setItemFlag(item, status != 'flagged'),
                icon: Icon(
                  status == 'flagged' ? Icons.flag_outlined : Icons.flag,
                  color: status == 'flagged' ? Colors.green : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildOverviewTab() {
    final totalUsers = _users.length;
    final totalItems = _items.length;
    final verifiedUsers = _users.where(_isVerified).length;
    final bannedUsers = _users.where(_isBanned).length;
    final flaggedItems =
        _items.where((i) => (i['status'] ?? '') == 'flagged').length;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Platform Snapshot',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        title: 'Total Users',
                        value: '$totalUsers',
                        icon: Icons.people,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiCard(
                        title: 'Verified',
                        value: '$verifiedUsers',
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        title: 'Total Items',
                        value: '$totalItems',
                        icon: Icons.inventory_2,
                        color: kSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiCard(
                        title: 'Flagged Items',
                        value: '$flaggedItems',
                        icon: Icons.flag,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _kpiCard(
                  title: 'Banned Users',
                  value: '$bannedUsers',
                  icon: Icons.block,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'Quick Actions',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.campaign),
                    label: const Text('Send Broadcast'),
                    onPressed: _sendBroadcast,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shield),
                    label: const Text('Review Flagged Items'),
                    onPressed: () {
                      setState(() => _itemFilter = 'Flagged');
                      DefaultTabController.of(context).animateTo(2);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'Admin Essentials',
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.receipt_long, color: kPrimary),
                  title: Text('Audit log'),
                  subtitle: Text('Track all admin actions and moderation events'),
                ),
                Divider(height: 8),
                ListTile(
                  leading: Icon(Icons.report, color: Colors.orange),
                  title: Text('User reports'),
                  subtitle: Text('Review reports and assign actions quickly'),
                ),
                Divider(height: 8),
                ListTile(
                  leading: Icon(Icons.rule, color: Colors.green),
                  title: Text('Policy center'),
                  subtitle: Text('Update rules, templates, and default warnings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'User Directory',
            child: Column(
              children: [
                TextField(
                  controller: _userSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: kBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    'All',
                    'Active',
                    'Offline',
                    'Unverified',
                    'Banned',
                  ].map((f) {
                    final selected = _userFilter == f;
                    return ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _userFilter = f),
                      selectedColor: kPrimary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: selected ? kPrimary : kDark,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'Users',
            child: _filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : Column(
                    children: _filteredUsers.map(_buildUserCard).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Item Moderation',
            child: Column(
              children: [
                TextField(
                  controller: _itemSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search items by name or owner',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: kBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Active', 'Flagged', 'Pending'].map((f) {
                    final selected = _itemFilter == f;
                    return ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _itemFilter = f),
                      selectedColor: kPrimary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: selected ? kPrimary : kDark,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'Items',
            child: _filteredItems.isEmpty
                ? const Center(child: Text('No items found'))
                : Column(
                    children: _filteredItems.map(_buildItemCard).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Moderation Queue',
          child: Column(
            children: [
              const Text(
                'Track escalations, appeals, and high-risk listings.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      title: 'Appeals',
                      value: '0',
                      icon: Icons.gavel,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _kpiCard(
                      title: 'Escalations',
                      value: '0',
                      icon: Icons.priority_high,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _sectionCard(
          title: 'Safety Playbooks',
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.rule_folder, color: kPrimary),
                title: Text('Standard moderation rules'),
                subtitle: Text('Built-in rules for fast, consistent decisions'),
              ),
              Divider(height: 8),
              ListTile(
                leading: Icon(Icons.phone_in_talk, color: Colors.green),
                title: Text('Support escalation'),
                subtitle: Text('Fast path for critical cases'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: kBackground,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 170,
                    backgroundColor: kPrimary,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
                      title: const Text(
                        'Admin Control Center',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimary, kSecondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_users.length} users • ${_items.length} items',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottom: const TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: kAccent,
                      tabs: [
                        Tab(text: 'Overview'),
                        Tab(text: 'Users'),
                        Tab(text: 'Items'),
                        Tab(text: 'Safety'),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _buildOverviewTab(),
                    _buildUsersTab(),
                    _buildItemsTab(),
                    _buildSafetyTab(),
                  ],
                ),
              ),
      ),
    );
  }
}
