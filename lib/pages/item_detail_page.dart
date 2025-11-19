import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_form_page.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String currentUser;
  final void Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onDelete;

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.index,
    required this.currentUser,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  late Map<String, dynamic> item;

  @override
  void initState() {
    super.initState();
    item = Map<String, dynamic>.from(widget.item);
  }

  Future<void> _editItem() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemFormPage(
          categories: const ['All', 'Electronics', 'Appliances', 'Tools'],
          existingItem: item,
        ),
      ),
    );
    if (res != null && res is Map<String, dynamic>) {
      setState(() => item = Map<String, dynamic>.from(res));
      widget.onUpdate(item);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = item['owner'] == widget.currentUser;
    final imagePath = item['image'] as String?;
    Widget imageWidget = const SizedBox.shrink();

    if (imagePath != null && imagePath.isNotEmpty) {
      final f = File(imagePath);
      if (f.existsSync()) {
        imageWidget = Image.file(f, height: 220, fit: BoxFit.cover);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name'] ?? 'Item'),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
          if (isOwner)
            IconButton(icon: const Icon(Icons.edit), onPressed: _editItem),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imagePath != null) imageWidget,
          const SizedBox(height: 12),
          Text(
            item['name'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Category: ${item['category'] ?? ''}'),
          const SizedBox(height: 4),
          Text('Price: Rs ${item['price'] ?? ''}'),
          const SizedBox(height: 12),
          Text(item['description'] ?? ''),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: isOwner
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Book Item'),
                        content: Text('Request booking for "${item['name']}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking requested'),
                                ),
                              );
                            },
                            child: const Text('Request'),
                          ),
                        ],
                      ),
                    );
                  },
            icon: const Icon(Icons.shopping_cart),
            label: Text(isOwner ? 'Cannot book your own item' : 'Book Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOwner ? Colors.grey : const Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }
}
