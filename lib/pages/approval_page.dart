import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ApprovalPage extends StatefulWidget {
  final String bookingId;
  const ApprovalPage({super.key, required this.bookingId});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  bool loading = true;
  List<Map<String, dynamic>> bookings = [];

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
      bookings = [res];
      loading = false;
    });
  }

  Future<void> _updateStatus(
    Map<String, dynamic> booking,
    String status,
  ) async {
    setState(() => loading = true);

    final renterId = booking['renter_id'];
    final itemName = booking['item']['name'];

    await Supabase.instance.client
        .from('bookings')
        .update({'status': status})
        .eq('id', widget.bookingId);

    /// CREATE NOTIFICATION
    await Supabase.instance.client.from('notifications').insert({
      'user_id': renterId,
      'title': status == 'active'
          ? 'Booking approved for $itemName'
          : 'Booking rejected for $itemName',
      'owner': Supabase.instance.client.auth.currentUser?.email ?? 'Owner',
      'booking_id': widget.bookingId,
      'body': 'Filler words',
    });

    await _load();

    setState(() => loading = false);
  }

  List<String> normalizeImages(dynamic raw) {
    if (raw is List) return raw.whereType<String>().toList();
    if (raw is String && raw.startsWith('[')) {
      try {
        return List<String>.from(jsonDecode(raw));
      } catch (_) {}
    }
    if (raw is String && raw.startsWith('http')) return [raw];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (bookings.isEmpty) {
      return const Scaffold(body: Center(child: Text('No pending approvals')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          final images = normalizeImages(b['item']['images']);
          final thumb = images.isNotEmpty ? images.first : null;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: thumb != null
                            ? Image.network(
                                thumb,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.inventory_2_outlined),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['item']['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Renter: ${b['renter']['full_name']}'),
                            Text('${b['from_date']} → ${b['to_date']}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () => _updateStatus(b, 'active'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () => _updateStatus(b, 'cancelled'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
