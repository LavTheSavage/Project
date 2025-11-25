import 'dart:io' show File;
import 'package:flutter/material.dart';

class MyRentalsPage extends StatelessWidget {
  final List<Map<String, dynamic>> rentals;
  const MyRentalsPage({super.key, this.rentals = const []});

  @override
  Widget build(BuildContext context) {
    final pending = rentals
        .where(
          (it) =>
              (it['status'] ?? '').toString().toLowerCase() == 'pending' &&
              it['rentedBy'] != null,
        )
        .toList();
    final booked = rentals
        .where(
          (it) =>
              (it['status'] ?? '').toString().toLowerCase() != 'pending' &&
              it['rentedBy'] != null,
        )
        .toList();

    Widget buildSection(
      String title,
      List<Map<String, dynamic>> items, {
      bool isPending = false,
    }) {
      if (items.isEmpty) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF263238),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              final owner = item['owner'] ?? '—';
              final when = item['rentedAt'] ?? '';
              final pricePerDay = item['price'] != null
                  ? (item['price'] is num
                        ? item['price'] as num
                        : double.tryParse(item['price'].toString()) ?? 0)
                  : 0;
              // Calculate days from bookingFrom and bookingTo if available
              int days = 1;
              if (item['bookingFrom'] != null && item['bookingTo'] != null) {
                final from = DateTime.tryParse(item['bookingFrom'].toString());
                final to = DateTime.tryParse(item['bookingTo'].toString());
                if (from != null && to != null) {
                  days = to.difference(from).inDays + 1;
                }
              } else if (item['days'] is int) {
                days = item['days'];
              }
              final totalPrice = pricePerDay * days;
              // leading image or icon
              Widget leading = const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(
                  Icons.inventory_2,
                  color: Color(0xFF1E88E5),
                  size: 28,
                ),
              );
              final imagePath = item['image'] as String?;
              if (imagePath != null && imagePath.isNotEmpty) {
                final f = File(imagePath);
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
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(item['name'] ?? ''),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rented from: $owner'),
                          if (when != '')
                            Text('Requested: ${_formatDate(when)}'),
                          Text(
                            'Price per day: Rs ${pricePerDay.toStringAsFixed(0)}',
                          ),
                          Text('Days: $days'),
                          Text(
                            'Total price: Rs ${totalPrice.toStringAsFixed(0)}',
                          ),
                          if (item['description'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Description: ${item['description']}',
                              ),
                            ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        leading,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rented from: $owner',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              if (when != '')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Requested: ${_formatDate(when)}',
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              // Price per day
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Price per day: Rs ${pricePerDay.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFF1E88E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              // Days
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Days: $days',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              // Total price
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Total Price: Rs ${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFF1E88E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
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
                                        color: isPending
                                            ? Colors.orange.shade700
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Container()),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF1E88E5),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(item['name'] ?? ''),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Rented from: $owner'),
                                              if (when != '')
                                                Text(
                                                  'Requested: ${_formatDate(when)}',
                                                ),
                                              Text(
                                                'Price per day: Rs ${pricePerDay.toStringAsFixed(0)}',
                                              ),
                                              Text('Days: $days'),
                                              Text(
                                                'Total price: Rs ${totalPrice.toStringAsFixed(0)}',
                                              ),
                                              if (item['description'] != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    'Description: ${item['description']}',
                                                  ),
                                                ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: (pending.isEmpty && booked.isEmpty)
            ? const Center(
                child: Text(
                  'You have no rentals yet.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
            : ListView(
                children: [
                  buildSection('Pending', pending, isPending: true),
                  buildSection('Booked', booked, isPending: false),
                ],
              ),
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
