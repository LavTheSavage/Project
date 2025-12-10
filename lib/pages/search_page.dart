import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_detail_page.dart';
import 'booking_page.dart';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> categories;
  final void Function(int, Map<String, dynamic>) onUpdate;
  final void Function(int) onDelete;
  final String currentUser;

  const SearchPage({
    super.key,
    required this.items,
    required this.categories,
    required this.onUpdate,
    required this.onDelete,
    required this.currentUser,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  String _categoryFilter = 'All';
  String _sortBy = 'price_desc';

  @override
  Widget build(BuildContext context) {
    // Filter items
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

    // Sort items
    final sorted = List<Map<String, dynamic>>.from(filtered);
    if (_sortBy == 'price_asc') {
      sorted.sort(
        (a, b) => (double.tryParse(a['price']?.toString() ?? '0') ?? 0)
            .compareTo(double.tryParse(b['price']?.toString() ?? '0') ?? 0),
      );
    } else if (_sortBy == 'price_desc') {
      sorted.sort(
        (a, b) => (double.tryParse(b['price']?.toString() ?? '0') ?? 0)
            .compareTo(double.tryParse(a['price']?.toString() ?? '0') ?? 0),
      );
    } else if (_sortBy == 'newest') {
      sorted.sort((a, b) {
        final ta = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
        final tb = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    }

    return SafeArea(
      child: Container(
        color: const Color(0xFFF5F7FA),
        padding: EdgeInsets.fromLTRB(
          10,
          10,
          10,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Search + sort
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for items... (name, category, owner)',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF263238),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF263238),
                              ),
                              onPressed: () => setState(() => _query = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFF263238)),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Text('Price ↑'),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text('Price ↓'),
                    ),
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v ?? 'price_desc'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Category chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.categories.map((cat) {
                  final selected = _categoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? Colors.white : Color(0xFF263238),
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF90CAF9),
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() => _categoryFilter = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Item list
            Expanded(
              child: sorted.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching items found 🔍',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF263238),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, i) {
                        final item = sorted[i];
                        final originalIndex = widget.items.indexOf(item);
                        final isOwner = item['owner'] == widget.currentUser;
                        final imagePath = item['image'] as String?;
                        Widget leading = const Icon(
                          Icons.inventory_2,
                          color: Color(0xFF1E88E5),
                          size: 56,
                        );
                        if (imagePath != null && File(imagePath).existsSync()) {
                          leading = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(imagePath),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailPage(
                                item: Map<String, dynamic>.from(item),
                                index: originalIndex,
                                currentUser: widget.currentUser,
                                onUpdate: (updated) =>
                                    widget.onUpdate(originalIndex, updated),
                                onDelete: () => widget.onDelete(originalIndex),
                              ),
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            child: IntrinsicHeight(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Hero(
                                      tag: 'search-item-$originalIndex',
                                      child: leading,
                                    ),
                                    const SizedBox(width: 12),

                                    // ============================
                                    //    TEXT COLUMN START
                                    // ============================
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // TITLE + CATEGORY ROW
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF263238),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),

                                              // CATEGORY CHIP
                                              Chip(
                                                label: Text(
                                                  item['category'] ?? '-',
                                                  style: const TextStyle(
                                                    color: Color(0xFF263238),
                                                  ),
                                                ),
                                                padding: EdgeInsets.zero,
                                                backgroundColor: const Color(
                                                  0xFF90CAF9,
                                                ).withOpacity(0.25),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 6),

                                          // OWNER
                                          SizedBox(
                                            height: 27,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  child: Text(
                                                    item['owner']?[0] ?? '?',
                                                    style: const TextStyle(
                                                      color: Color(0xFF263238),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item['owner'] ?? '-',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Color(0xFF263238),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          // LOCATION SECTION
                                          if (item['location'] != null)
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    item['location'],
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF263238),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                          const SizedBox(height: 6),

                                          // DATE + TIME (AUTO WRAPS, NO OVERFLOW)
                                          Builder(
                                            builder: (_) {
                                              final raw =
                                                  item['createdAt'] ??
                                                  item['created_at'];
                                              if (raw == null)
                                                return const SizedBox.shrink();

                                              final dt = raw is DateTime
                                                  ? raw
                                                  : DateTime.tryParse(raw) ??
                                                        DateTime(2000);

                                              final formattedDate =
                                                  "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
                                              final formattedTime =
                                                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                                              return Wrap(
                                                spacing: 12,
                                                runSpacing: 4,
                                                children: [
                                                  Text(
                                                    "Listed: $formattedDate",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF263238),
                                                    ),
                                                  ),
                                                  Text(
                                                    "Time: $formattedTime",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF263238),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ============================
                                    //   PRICE + BOOK SECTION (constrained)
                                    // ============================
                                    // Limit width to avoid pushing the middle column
                                    // and causing overflow (e.g. "overflowed by 2.8 pixels").
                                    SizedBox(
                                      width: 104,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEDF7FF),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Rs ${item['price']}',
                                              style: const TextStyle(
                                                color: Color(0xFF1E88E5),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isOwner
                                                  ? Colors.grey
                                                  : const Color(0xFFFFC107),
                                            ),
                                            onPressed: isOwner
                                                ? null
                                                : () => Navigator.push(
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
                                                  ),
                                            child: Text(
                                              isOwner ? 'Owned' : 'Book',
                                              style: const TextStyle(
                                                color: Color(0xFF263238),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
      ),
    );
  }
}
