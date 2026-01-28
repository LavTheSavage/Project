import 'dart:convert';
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
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // ================= FETCH =================
  Future<void> fetchNotifications() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final res = await supabase
          .from('notifications')
          .select('''
id,
title,
body,
created_at,
handled,
booking_id,
booking:bookings (
  id,
  from_date,
  to_date,
  total_days,
  status,
  received_by_renter,
  item:items (name, images),
  renter:profiles!bookings_renter_id_fkey (id, full_name)
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
      debugPrint('Fetch error: $e');
      loading = false;
    }
  }

  // ================= HELPERS =================
  String formatDateTime(dynamic ts) {
    if (ts == null) return '';
    return DateFormat(
      'yyyy MMM dd, hh:mm a',
    ).format(DateTime.parse(ts).toLocal());
  }

  List<String> normalizeImages(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<String>().toList();
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.whereType<String>().toList();
      } catch (_) {
        if (raw.startsWith('http')) return [raw];
      }
    }
    return [];
  }

  Future<void> markHandled(int id) async {
    await supabase.from('notifications').update({'handled': true}).eq('id', id);
  }

  Widget statusChip(String? status) {
    final color =
        {
          'pending': Colors.orange,
          'approved': Colors.blue,
          'declined': Colors.red,
          'active': Colors.green,
        }[status] ??
        Colors.grey;

    return Chip(
      label: Text(
        status?.toUpperCase() ?? '',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  // ================= RECEIVED BUTTON =================
  Future<void> markReceived({
    required int bookingId,
    required int notificationId,
  }) async {
    await supabase
        .from('bookings')
        .update({'received_by_renter': true, 'status': 'active'})
        .eq('id', bookingId);

    await markHandled(notificationId);
    fetchNotifications();
  }

  // ================= UI =================
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
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: 200),
                  Center(child: Text("No notifications yet")),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final booking = n['booking'];
                  final item = booking?['item'];
                  final renter = booking?['renter'];

                  final images = normalizeImages(item?['images']);
                  final thumb = images.isNotEmpty ? images.first : null;

                  final canOpen = booking != null;

                  final showReceivedBtn =
                      booking?['status'] == 'approved' &&
                      booking?['received_by_renter'] == false &&
                      renter?['id'] == supabase.auth.currentUser!.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: canOpen
                              ? () async {
                                  await markHandled(n['id']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ApprovalPage(
                                        bookingId: n['booking_id'],
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: thumb != null
                                    ? Image.network(
                                        thumb,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, progress) {
                                          if (progress == null) return child;
                                          return const SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.blue.shade100,
                                        child: Icon(
                                          Icons.notifications,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n['title'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        statusChip(booking?['status']),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n['body'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    if (renter?['full_name'] != null)
                                      Text(
                                        "Renter: ${renter['full_name']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
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
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),

                        // ===== RECEIVED BUTTON =====
                        if (showReceivedBtn) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle),
                              label: const Text("Received Item"),
                              onPressed: () => markReceived(
                                bookingId: booking['id'],
                                notificationId: n['id'],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
