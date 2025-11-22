import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_detail_page.dart';
import 'booking_page.dart';

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
  DateTimeRange? _selectedRange;
  int? _selectedIndex;
  double? _liveTotal;
  String _query = '';
  String _categoryFilter = 'All';
  String _sortBy = 'price_desc';

  @override
  Widget build(BuildContext context) {
    // Improved search: match name, category, or owner
    final filtered = widget.items.where((it) {
      final name = (it['name'] ?? '').toString().toLowerCase();
      final owner = (it['owner'] ?? '').toString().toLowerCase();
      final category = (it['category'] ?? '').toString().toLowerCase();
      final q = _query.toLowerCase();
      final match =
          name.contains(q) || owner.contains(q) || category.contains(q);
      final matchCategory =
          _categoryFilter == 'All' || it['category'] == _categoryFilter;
      return match && matchCategory;
    }).toList();
    final priceFiltered = filtered;

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
          // Improved search bar with clear button, removed min/max price
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for items... (name, category, owner)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _query = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
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
                        size: 56,
                      );
                      if (imagePath != null && imagePath.isNotEmpty) {
                        final f = File(imagePath);
                        if (f.existsSync()) {
                          leading = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              f,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                      }
                      final priceText = 'Rs ${item['price'] ?? '-'}';
                      final pricePerDay =
                          double.tryParse(item['price']?.toString() ?? '') ?? 0;
                      final isSelected = _selectedIndex == i;
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
                                    index: originalIndex,
                                    currentUser: widget.currentUser,
                                    onUpdate: (updated) =>
                                        widget.onUpdate(originalIndex, updated),
                                    onDelete: () {},
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
                                    tag: 'search-item-$originalIndex',
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: leading,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(
                                                item['category'] ?? 'Unknown',
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              child: Text(
                                                (item['owner'] ?? 'U')
                                                        .toString()
                                                        .isNotEmpty
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 120,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDF7FF),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                      if (isSelected && _selectedRange != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4.0,
                                          ),
                                          child: Text(
                                            'Total: Rs ${_liveTotal?.toStringAsFixed(2) ?? (pricePerDay * (_selectedRange!.end.difference(_selectedRange!.start).inDays + 1)).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: isOwner
                                              ? null
                                              : () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          BookingPage(
                                                            item:
                                                                Map<
                                                                  String,
                                                                  dynamic
                                                                >.from(item),
                                                            index:
                                                                originalIndex,
                                                            currentUser: widget
                                                                .currentUser,
                                                            onUpdate:
                                                                (
                                                                  i,
                                                                  updated,
                                                                ) => widget
                                                                    .onUpdate(
                                                                      i,
                                                                      updated,
                                                                    ),
                                                            allItems:
                                                                widget.items,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          child: Text(
                                            isOwner ? 'Owned' : 'Book',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
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
          ),
        ],
      ),
    );
  }
}
