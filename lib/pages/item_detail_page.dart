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
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    item = Map<String, dynamic>.from(widget.item);
    isFavorite = item['favorite'] == true;
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
      setState(() {
        item = Map<String, dynamic>.from(res);
        isFavorite = item['favorite'] == true;
      });
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

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      item['favorite'] = isFavorite;
    });
    widget.onUpdate(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
      ),
    );
  }

  void _shareItem() {
    // minimal placeholder for share. Replace with share package if desired.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share link: ${item['name'] ?? 'item'}')),
    );
  }

  void _openImagePreview(String path) {
    final f = File(path);
    if (!f.existsSync()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black),
          backgroundColor: Colors.black,
          body: Center(child: InteractiveViewer(child: Image.file(f))),
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String subtitle, {
    Color? color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = item['owner'] == widget.currentUser;
    final imagePath = item['image'] as String?;
    final hasImage =
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name'] ?? 'Item'),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareItem),
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
          // Image card
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: hasImage ? () => _openImagePreview(imagePath) : null,
              child: SizedBox(
                height: 220,
                child: hasImage
                    ? Hero(
                        tag: 'item_image_${widget.index}_${item['name']}',
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No image available',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['subtitle'] ?? '',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: const Color(0xFFE3F2FD),
                    label: Text(
                      item['status'] ?? 'Available',
                      style: const TextStyle(color: Color(0xFF1E88E5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Individual small cards (Category, Price, Owner, Condition)
          SizedBox(
            height: 110,
            child: Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.category,
                    'Category',
                    item['category'] ?? 'N/A',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoCard(
                    Icons.attach_money,
                    'Price',
                    'Rs ${item['price'] ?? '0'}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoCard(
                    Icons.person,
                    'Owner',
                    item['owner'] ?? 'Unknown',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoCard(
                    Icons.app_settings_alt,
                    'Condition',
                    item['condition'] ?? 'Good',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Description card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(item['description'] ?? 'No description provided.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isOwner
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Book Item'),
                              content: Text(
                                'Request booking for "${item['name']}"?',
                              ),
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
                  label: Text(
                    isOwner ? 'Cannot book your own item' : 'Book Item',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwner
                        ? Colors.grey
                        : const Color(0xFF1E88E5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isOwner
                      ? _editItem
                      : () {
                          final owner = item['owner'] ?? 'Owner';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Contacted $owner (placeholder)'),
                            ),
                          );
                        },
                  icon: Icon(isOwner ? Icons.edit : Icons.message),
                  label: Text(isOwner ? 'Edit' : 'Contact Owner'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
