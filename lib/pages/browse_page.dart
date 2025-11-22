import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_detail_page.dart';
import 'booking_page.dart';

class BrowsePage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<String> categories;
  final void Function(int) onDelete;
  final void Function(int, Map<String, dynamic>) onUpdate;
  final String currentUser;

  const BrowsePage({
    super.key,
    required this.items,
    required this.categories,
    required this.onDelete,
    required this.onUpdate,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No items available'));

    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isOwner = item['owner'] == currentUser;
          final imagePath = item['image'] as String?;
          Widget leading = const Icon(
            Icons.inventory_2,
            color: Color(0xFF1E88E5),
            size: 56,
          );
          if (imagePath != null && imagePath.isNotEmpty) {
            final f = File(imagePath);
            if (f.existsSync()) {
              leading = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(f, width: 72, height: 72, fit: BoxFit.cover),
              );
            }
          }

          final priceText = 'Rs ${item['price'] ?? '-'}';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: SizedBox(
              height: 140,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailPage(
                        item: Map<String, dynamic>.from(item),
                        index: index,
                        currentUser: currentUser,
                        onUpdate: (updated) => onUpdate(index, updated),
                        onDelete: () => onDelete(index),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'item-$index',
                        child: SizedBox(width: 72, height: 72, child: leading),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Category chip on its own line
                            Row(
                              children: [
                                Chip(
                                  label: Text(item['category'] ?? 'Unknown'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Owner below the tag for a cleaner look
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Text(
                                    (item['owner'] ?? 'U').toString().isNotEmpty
                                        ? item['owner']
                                              .toString()[0]
                                              .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['owner'] ?? '—',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Your listing',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Trailing column constrained to avoid overflow
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF7FF),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                priceText,
                                style: const TextStyle(
                                  color: Color(0xFF1E88E5),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 84,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOwner
                                    ? Colors.grey
                                    : const Color(0xFF43A047),
                                minimumSize: const Size(84, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: isOwner
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BookingPage(
                                            item: Map<String, dynamic>.from(
                                              item,
                                            ),
                                            index: index,
                                            currentUser: currentUser,
                                            onUpdate: (i, updated) =>
                                                onUpdate(i, updated),
                                            allItems: items,
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                isOwner ? 'Owned' : 'Book',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
