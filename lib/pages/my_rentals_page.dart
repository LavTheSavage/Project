import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class MyRentalsPage extends StatefulWidget {
  const MyRentalsPage({super.key});

  @override
  State<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage> {
  bool loading = true;
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final ownerName = item?['owner']?['full_name'] ?? '—';
    final res = await Supabase.instance.client
        .from('bookings')
        .select('''
      id,
      status,
      from_date,
      to_date,
      item:items (
        id,
        name,
        price,
        images,
        owner:profiles (
          full_name
        )
      )
    ''')
        .eq('renter_id', uid)
        .inFilter('status', ['pending', 'approved', 'active'])
        .order('created_at', ascending: false);

    setState(() {
      bookings = List<Map<String, dynamic>>.from(res);
      loading = false;
    });
  }

  Future<void> returnItem(int bookingId) async {
    await Supabase.instance.client
        .from('bookings')
        .update({'status': 'completed'})
        .eq('id', bookingId);

    await _load(); // refresh list
  }

  List<String> normalizeImages(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw.whereType<String>().toList();
    }

    if (raw is String) {
      final s = raw.trim();

      if (s.startsWith('[')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            return decoded.whereType<String>().toList();
          }
        } catch (_) {}
      }

      if (s.startsWith('http')) {
        return [s];
      }
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pending = bookings.where((b) => b['status'] == 'pending').toList();
    final booked = bookings
        .where((b) => ['approved', 'active'].contains(b['status']))
        .toList();

    Widget buildSection(
      String title,
      List<Map<String, dynamic>> list, {
      required bool isPending,
    }) {
      if (list.isEmpty) {
        return Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text('No $title rentals'),);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final b = list[i];
              final item = b['item'];
              final ownerName = b['owner']?['full_name'] ?? '—';

              final pricePerDay =
                  double.tryParse(item?['price']?.toString() ?? '0') ?? 0;

              final from = DateTime.parse(b['from_date']);
              final to = DateTime.parse(b['to_date']);
              final days = to.difference(from).inDays + 1;
              final total = pricePerDay * days;

              final images = normalizeImages(item?['images']);
              final thumb = images.isNotEmpty ? images.first : null;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      /// IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: thumb != null
                            ? Image.network(
                                thumb,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 68,
                                height: 68,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.inventory_2),
                              ),
                      ),

                      const SizedBox(width: 12),

                      /// CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item?['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Rented from: $ownerName'),
                            Text(
                              'Rs ${pricePerDay.toStringAsFixed(0)} / day',
                              style: const TextStyle(
                                color: Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Days: $days'),
                            Text(
                              'Total: Rs ${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// STATUS
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.amber.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
final status = b['status'];

child: Text(
  status == 'pending'
      ? 'Pending'
      : status == 'approved'
          ? 'Approved'
          : 'Active',
  style: TextStyle(
    fontWeight: FontWeight.bold,
    color: status == 'pending'
        ? Colors.orange
        : status == 'approved'
            ? Colors.blue
            : Colors.green,
  ),
),

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPending
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                            
                          ],
                        ),
                      ),
                    ],
                
                ),
              );
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: (pending.isEmpty && booked.isEmpty)
            ? const Center(child: Text('You have no rentals yet'))
            : ListView(
                children: [
                  buildSection('Pending', pending, isPending: true),
                  buildSection('Booked', booked, isPending: false),
                ],
              ),
      ),
    );
  }
}
