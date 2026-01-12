import 'dart:io';
import 'package:flutter/material.dart';
import 'item_detail_page.dart';

class MyListingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? currentUser;
  final void Function(int) onDelete;
  final void Function(int, Map<String, dynamic>) onUpdate;

  const MyListingsPage({
    super.key,
    required this.items,
    required this.currentUser,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final myItems = items.where((it) => it['owner_id'] == currentUser).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: myItems.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No listings yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap + to list your first item',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: myItems.length,
              itemBuilder: (context, idx) {
                final item = myItems[idx];
                final originalIndex = items.indexOf(item);

                Widget leading = const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF1E88E5),
                );

                final imagePath = item['image'] as String?;
                if (imagePath != null && imagePath.isNotEmpty) {
                  final file = File(imagePath);
                  if (file.existsSync()) {
                    leading = ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        file,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: leading,
                    title: Text(item['name'] ?? ''),
                    subtitle: Text(
                      'Category: ${item['category'] ?? ''}\n'
                      'Price: Rs ${item['price'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'delete') {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete listing'),
                              content: const Text('Remove this listing?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onDelete(originalIndex);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (v == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailPage(
                                item: Map<String, dynamic>.from(item),
                                index: originalIndex,
                                currentUser: currentUser,
                                onUpdate: onUpdate,
                                onDelete: onDelete,
                                allItems: items,
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('View / Edit'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailPage(
                            item: Map<String, dynamic>.from(item),
                            index: originalIndex,
                            currentUser: currentUser,
                            onUpdate: onUpdate,
                            onDelete: onDelete,
                            allItems: items,
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
