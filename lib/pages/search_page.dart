import 'dart:io';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> categories;

  const SearchPage({super.key, required this.items, required this.categories});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final matchesName = item['name'].toString().toLowerCase().contains(
        _query.toLowerCase(),
      );
      final matchesCategory =
          _categoryFilter == 'All' || item['category'] == _categoryFilter;
      return matchesName && matchesCategory;
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
            onChanged: (value) => setState(() {
              _query = value;
            }),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.categories
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _categoryFilter == cat,
                        onSelected: (selected) {
                          setState(() {
                            _categoryFilter = cat;
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'No matching items found 🔍',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
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
