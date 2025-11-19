import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_detail_page.dart';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> categories;
  final void Function(int, Map<String, dynamic>) onUpdate;
  final String currentUser;

  const SearchPage({
    super.key,
    required this.items,
    required this.categories,
    required this.onUpdate,
    required this.currentUser,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((it) {
      final name = (it['name'] ?? '').toString().toLowerCase();
      final matchName = name.contains(_query.toLowerCase());
      final matchCategory =
          _categoryFilter == 'All' || it['category'] == _categoryFilter;
      return matchName && matchCategory;
    }).toList();

    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.categories.map((cat) {
                final selected = _categoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() => _categoryFilter = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching items found 🔍',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final originalIndex = widget.items.indexOf(item);
                      final isOwner = item['owner'] == widget.currentUser;
                      final imagePath = item['image'] as String?;
                      Widget leading = const Icon(
                        Icons.inventory_2,
                        color: Color(0xFF1E88E5),
                      );
                      if (imagePath != null && imagePath.isNotEmpty) {
                        final f = File(imagePath);
                        if (f.existsSync()) {
                          leading = Image.file(
                            f,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          );
                        }
                      }
                      return Card(
                        child: ListTile(
                          leading: leading,
                          title: Text(item['name'] ?? ''),
                          subtitle: Text(
                            'Rs ${item['price'] ?? ''} • ${item['category'] ?? ''}',
                          ),
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
                                        content: Text(
                                          'Book "${item['name']}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Booking requested',
                                                  ),
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
                                  index: originalIndex,
                                  currentUser: widget.currentUser,
                                  onUpdate: (updated) =>
                                      widget.onUpdate(originalIndex, updated),
                                  onDelete: () {},
                                ),
                              ),
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
