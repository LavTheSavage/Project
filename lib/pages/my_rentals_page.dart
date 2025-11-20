import 'dart:io' show File;
import 'package:flutter/material.dart';

class MyRentalsPage extends StatelessWidget {
  final List<Map<String, dynamic>> rentals;
  const MyRentalsPage({super.key, this.rentals = const []});

  @override
  Widget build(BuildContext context) {
    final r = rentals.where((it) => it['rentedBy'] != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: r.isEmpty
            ? const Center(
                child: Text(
                  'You have no rentals yet.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
            : ListView.separated(
                itemCount: r.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = r[i];
                  final renter = item['rentedBy'] ?? '—';
                  final when = item['rentedAt'] ?? '';
                  final status = (item['status'] ?? '')
                      .toString()
                      .toLowerCase();
                  final isPending = status == 'pending';

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

                  return Card(
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
                                  'Rented by: $renter',
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
                                        isPending ? 'Pending' : 'Active',
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
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(item['name'] ?? ''),
                                          content: Text(
                                            'Rented by: $renter\n${when != '' ? 'Requested: ${_formatDate(when)}\n' : ''}Status: ${status.isEmpty ? 'active' : status}',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
