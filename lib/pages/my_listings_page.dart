import 'dart:io';
import 'package:flutter/material.dart';
import 'item_detail_page.dart';

class MyListingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String currentUser;
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
    final myItems = items.where((it) => it['owner'] == currentUser).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: myItems.isEmpty
          ? const Center(child: Text("You have not listed anything yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: myItems.length,
              itemBuilder: (context, idx) {
                final item = myItems[idx];
                final originalIndex = items.indexOf(item);
                final imagePath = item['image'] as String?;
                Widget leading = const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF1E88E5),
                );
                if (imagePath != null && imagePath.isNotEmpty) {
                  final file = File(imagePath);
                  if (file.existsSync()) {
                    leading = Image.file(
                      file,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    );
                  }
                }
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: leading,
                    title: Text(item['name'] ?? ''),
                    subtitle: Text(
                      "Category: ${item['category'] ?? ''}\nPrice: Rs ${item['price'] ?? ''}",
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
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
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailPage(
                            item: Map<String, dynamic>.from(item),
                            index: originalIndex,
                            currentUser: currentUser,
                            onUpdate: (updated) =>
                                onUpdate(originalIndex, updated),
                            onDelete: () => onDelete(originalIndex),
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
