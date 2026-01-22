import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApprovalPage extends StatefulWidget {
  final String bookingId;
  const ApprovalPage({super.key, required this.bookingId});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  bool loading = true;
  Map<String, dynamic>? booking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await Supabase.instance.client
        .from('bookings')
        .select('''
          *,
          item:items (name, images),
          renter:profiles!bookings_renter_id_fkey (full_name)
        ''')
        .eq('id', widget.bookingId)
        .single();

    setState(() {
      booking = res;
      loading = false;
    });
  }

  /// OWNER → APPROVE
  Future<void> _approveBooking() async {
    setState(() => loading = true);

    final supabase = Supabase.instance.client;
    final renterId = booking!['renter_id'];
    final itemName = booking!['item']['name'];

    await supabase
        .from('bookings')
        .update({'status': 'approved', 'owner_approved': true})
        .eq('id', widget.bookingId);

    await supabase
        .from('notifications')
        .update({'handled': true})
        .eq('booking_id', widget.bookingId);

    await supabase.from('notifications').insert({
      'user_id': renterId,
      'type': 'booking_approved',
      'title': 'Booking approved for $itemName',
      'body': 'Your booking request has been approved.',
      'booking_id': widget.bookingId,
    });

    if (mounted) Navigator.pop(context, true);
  }

  /// OWNER → DECLINE (DELETE BOOKING)
  Future<void> _declineBooking(String reason) async {
    setState(() => loading = true);

    final supabase = Supabase.instance.client;
    final renterId = booking!['renter_id'];
    final itemName = booking!['item']['name'];

    await supabase.from('bookings').delete().eq('id', widget.bookingId);

    await supabase.from('notifications').insert({
      'user_id': renterId,
      'type': 'booking_declined',
      'title': 'Booking declined for $itemName',
      'body': 'Reason: $reason',
    });

    if (mounted) Navigator.pop(context, true);
  }

  /// RENTER → ITEM RECEIVED
  Future<void> _markReceived() async {
    await Supabase.instance.client
        .from('bookings')
        .update({'status': 'active', 'renter_received': true})
        .eq('id', widget.bookingId);

    _load();
  }

  List<String> normalizeImages(dynamic raw) {
    if (raw is List) return raw.whereType<String>().toList();
    if (raw is String && raw.startsWith('[')) {
      try {
        return List<String>.from(jsonDecode(raw));
      } catch (_) {}
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (loading || booking == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isOwner = booking!['owner_id'] == currentUserId;
    final isRenter = booking!['renter_id'] == currentUserId;
    final status = booking!['status'];

    final images = normalizeImages(booking!['item']['images']);
    final thumb = images.isNotEmpty ? images.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: thumb != null
                          ? Image.network(thumb, width: 70, height: 70)
                          : const Icon(Icons.inventory, size: 70),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking!['item']['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Renter: ${booking!['renter']['full_name']}'),
                          Text(
                            '${booking!['from_date']} → ${booking!['to_date']}',
                          ),
                        ],
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),

                const Divider(height: 30),

                /// DETAILS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoTile('Days', booking!['total_days'].toString()),
                    _infoTile('Total', '₹${booking!['total_price']}'),
                  ],
                ),

                const Spacer(),

                /// ACTIONS
                if (isOwner && status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _approveBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _declineBooking('Owner declined'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                ],

                if (isRenter && status == 'approved')
                  ElevatedButton(
                    onPressed: _markReceived,
                    child: const Text('Item Received'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ],
  );

  Widget _statusChip(String status) {
    final color =
        {
          'pending': Colors.orange,
          'approved': Colors.blue,
          'active': Colors.green,
          'completed': Colors.grey,
        }[status] ??
        Colors.black;

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}
