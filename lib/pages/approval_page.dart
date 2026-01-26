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

    try {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving booking: $e')));
      debugPrint('Error :$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
    setState(() => loading = true);

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'active', 'renter_received': true})
          .eq('id', widget.bookingId);

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot activate booking: already in use')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
      appBar: AppBar(title: const Text('Booking Details'), elevation: 0),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: thumb != null
                                ? Image.network(
                                    thumb,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.inventory,
                                      size: 40,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking!['item']['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${booking!['from_date']} → ${booking!['to_date']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _statusChip(status),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 24),

                      /// DETAILS SECTION
                      Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoTile('Days', booking!['total_days'].toString()),
                          _infoTile(
                            'Total Price',
                            '₹${booking!['total_price']}',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      /// ACTIONS
                      if (isOwner && status == 'pending') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: loading ? null : _approveBooking,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Decline'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: loading
                                    ? null
                                    : () => _declineBooking('Owner declined'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (isRenter && status == 'approved') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Item Received'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: loading ? null : _markReceived,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
