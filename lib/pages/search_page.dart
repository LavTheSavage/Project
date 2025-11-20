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
  String _sortBy = 'price_desc';
  String _minPrice = '';
  String _maxPrice = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((it) {
      final name = (it['name'] ?? '').toString().toLowerCase();
      final matchName = name.contains(_query.toLowerCase());
      final matchCategory =
          _categoryFilter == 'All' || it['category'] == _categoryFilter;
      return matchName && matchCategory;
    }).toList();

    // apply price filtering
    double? minP = double.tryParse(_minPrice);
    double? maxP = double.tryParse(_maxPrice);
    final priceFiltered = filtered.where((it) {
      final price = double.tryParse((it['price'] ?? '').toString()) ?? 0.0;
      if (minP != null && price < minP) return false;
      if (maxP != null && price > maxP) return false;
      return true;
    }).toList();

    // apply sorting
    final sorted = List<Map<String, dynamic>>.from(filtered);
    if (_sortBy == 'price_asc') {
      sorted.sort(
        (a, b) => (double.tryParse((a['price'] ?? '').toString()) ?? 0)
            .compareTo(double.tryParse((b['price'] ?? '').toString()) ?? 0),
      );
    } else if (_sortBy == 'price_desc') {
      sorted.sort(
        (a, b) => (double.tryParse((b['price'] ?? '').toString()) ?? 0)
            .compareTo(double.tryParse((a['price'] ?? '').toString()) ?? 0),
      );
    } else if (_sortBy == 'newest') {
      sorted.sort((a, b) {
        final ta = DateTime.tryParse((a['createdAt'] ?? '').toString());
        final tb = DateTime.tryParse((b['createdAt'] ?? '').toString());
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
    }

    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Min',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _minPrice = v),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 90,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Max',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _maxPrice = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'price_asc', child: Text('Price ↑')),
                  DropdownMenuItem(value: 'price_desc', child: Text('Price ↓')),
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                ],
                onChanged: (v) => setState(() => _sortBy = v ?? 'price_desc'),
              ),
            ],
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
            child: priceFiltered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching items found 🔍',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: priceFiltered.length,
                    itemBuilder: (context, i) {
                      final item = priceFiltered[i];
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
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: leading,
                          ),
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
                                              // mark item as pending and update upstream
                                              final updated =
                                                  Map<String, dynamic>.from(
                                                    item,
                                                  );
                                              updated['rentedBy'] =
                                                  widget.currentUser;
                                              updated['status'] = 'pending';
                                              updated['rentedAt'] =
                                                  DateTime.now()
                                                      .toIso8601String();
                                              widget.onUpdate(
                                                originalIndex,
                                                updated,
                                              );
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Booking requested — status: Pending',
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
