import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_detail_page.dart';

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
            size: 48,
          );
          if (imagePath != null && imagePath.isNotEmpty) {
            final file = File(imagePath);
            if (file.existsSync()) {
              leading = Image.file(
                file,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              );
            }
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: leading,
              title: Text(item['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: ${item['category'] ?? ''} • Rs ${item['price'] ?? ''}',
                  ),
                  if (isOwner) const SizedBox(height: 6),
                  if (isOwner)
                    const Text(
                      'Listed by you',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: isOwner ? Colors.grey : Colors.green,
                ),
                onPressed: isOwner
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Book Item'),
                            content: Text('Book "${item['name']}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Booking requested'),
                                    ),
                                  );
                                },
                                child: const Text('Book'),
                              ),
                            ],
                          ),
                        );
                      },
              ),
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
            ),
          );
        },
      ),
    );
  }
}
