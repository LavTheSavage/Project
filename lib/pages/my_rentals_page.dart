import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final now = DateTime.now().toIso8601String();

  final res = await Supabase.instance.client
      .from('bookings')
      .select('''
        *,
        item:items (
          id,
          name,
          price,
          images
        ),
        owner:profiles!bookings_owner_id_fkey (
          full_name
        )
      ''')
      .eq('renter_id', uid)
      .inFilter('status', ['pending', 'active'])
      .lte('from_date', now)
      .gte('to_date', now)
      .order('created_at', ascending: false);

  setState(() {
    bookings = List<Map<String, dynamic>>.from(res);
    loading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    final activeRentals = rentals.where((r) {
      final now = DateTime.now();
      final from = DateTime.parse(r['from_date']);
      final to = DateTime.parse(r['to_date']);
      return (r['renter_id'] == Supabase.instance.client.auth.currentUser?.id) &&
          (r['status'] == 'pending' || (from.isBefore(now) && to.isAfter(now)));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("My Rentals")),
      body: ListView.builder(
        itemCount: activeRentals.length,
        itemBuilder: (context, index) {
          final item = activeRentals[index];
          return ListTile(
            title: Text(item['name'] ?? ''),
            subtitle: Text("Rs ${item['price'] ?? 0}"),
          );
        },
      ),
    );
  }
}

Future<void> returnItem(Map<String, dynamic> rental) async {
  await supabase
      .from('bookings')
      .update({'status': 'completed'})
      .eq('item_id', rental['id'])
      .eq('renter_id', Supabase.instance.client.auth.currentUser?.id);

  // Optionally reload both Search and My Rentals
}



  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pending = bookings.where((b) => b['status'] == 'pending').toList();
    final booked = bookings.where((b) => b['status'] != 'pending').toList();

    Widget buildSection(
      String title,
      List<Map<String, dynamic>> list, {
      required bool isPending,
    }) {
      if (list.isEmpty) return const SizedBox();

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

              final pricePerDay = (item?['price'] ?? 0).toDouble();

              final from = DateTime.parse(b['from_date']);
              final to = DateTime.parse(b['to_date']);
              final days = to.difference(from).inDays + 1;
              final total = pricePerDay * days;

              Widget leading = const CircleAvatar(
                radius: 34,
                child: Icon(Icons.inventory_2),
              );

              final images = item?['images'];
              if (images is List && images.isNotEmpty) {
                final f = File(images.first);
                if (f.existsSync()) {
                  leading = ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      f,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                    ),
                  );
                }
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      leading,
                      const SizedBox(width: 12),
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
                              child: Text(
                                isPending ? 'Pending' : 'Booked',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPending
                                      ? Colors.orange
                                      : Colors.green,
                                ),
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
