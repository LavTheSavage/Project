import 'dart:io';
import 'package:flutter/material.dart';

class BrowsePage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> categories;
  final Function(int) onDelete;

  const BrowsePage({
    super.key,
    required this.items,
    required this.categories,
    required this.onDelete,
  });

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredItems = selectedCategory == 'All'
        ? widget.items
        : widget.items
              .where((item) => item['category'] == selectedCategory)
              .toList();

    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.categories
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selectedCategory == cat,
                        onSelected: (bool selected) {
                          setState(() {
                            selectedCategory = cat;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items yet — tap + to add one 📦',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: item['image'] != null
                              ? Image.file(
                                  File(item['image']),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.broken_image,
                                      color: Colors.red,
                                      size: 50,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.inventory_2,
                                  color: Color(0xFF1E88E5),
                                ),
                          title: Text(item['name'] ?? ''),
                          subtitle: Text(
                            'Price: Rs. ${item['price'] ?? ''}\nCategory: ${item['category']}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Item'),
                                  content: const Text(
                                    'Are you sure you want to delete this item?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        final originalIndex = widget.items
                                            .indexOf(item);
                                        if (originalIndex != -1) {
                                          widget.onDelete(originalIndex);
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/itemDetail',
                              arguments: item,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
