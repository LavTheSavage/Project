import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'approval_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool loading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final res = await Supabase.instance.client
          .from('notifications')
          .select('''
  id,
  title,
  body,
  created_at,
  booking_id,
  booking:bookings (
    from_date,
    to_date,
    total_days,
    status,
    item:items (name, images),
    renter:profiles!bookings_renter_id_fkey (full_name)
  )
''')
          .eq('user_id', userId)
          .eq('handled', false)
          .order('created_at', ascending: false);

      setState(() {
        notifications = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Error fetching notifications: $e');
    }
  }

  /// Format timestamp nicely
  String formatDateTime(dynamic ts) {
    if (ts == null) return '';
    final dt = DateTime.parse(ts.toString()).toLocal();
    return DateFormat('yyyy MMM dd, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final booking = n['booking'];
                final item = booking?['item'];
                final renter = booking?['renter'];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ApprovalPage(bookingId: n['booking_id']),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              item?['images'] != null &&
                                  (item['images'] as List).isNotEmpty
                              ? Image.network(
                                  item['images'][0],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.inventory),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item?['name'] ?? 'Item',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Requested by ${renter?['full_name'] ?? 'User'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${booking?['total_days']} days • ${booking?['from_date']} → ${booking?['to_date']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _statusChip(booking?['status']),
                              const SizedBox(height: 4),
                              Text(
                                formatDateTime(n['created_at']),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(String? status) {
    final color =
        {
          'pending': Colors.orange,
          'approved': Colors.blue,
          'declined': Colors.red,
          'active': Colors.green,
        }[status] ??
        Colors.grey;

    return Chip(
      label: Text(status?.toUpperCase() ?? ''),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
      padding: EdgeInsets.zero,
    );
  }
}
