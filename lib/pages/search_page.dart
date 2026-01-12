import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'item_detail_page.dart';
import 'booking_page.dart';
import 'dart:convert';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> categories;
  final void Function(int, Map<String, dynamic>) onUpdate;
  final void Function(int) onDelete;
  final String? currentUser;

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

  /// 🔥 Tracks items that should be hidden
  Set<int> unavailableItemIds = {};

  /// ✅ LOAD ONCE
  @override
  void initState() {
    super.initState();
    _loadUnavailableItems();
  }

  /// ✅ MOVED OUT OF build()
  Future<void> _loadUnavailableItems() async {
    final now = DateTime.now().toIso8601String();

    final res = await Supabase.instance.client
        .from('bookings')
        .select('item_id')
        .inFilter('status', ['pending', 'active'])
        .lte('from_date', now)
        .gte('to_date', now);

    if (!mounted) return;

    setState(() {
      unavailableItemIds = res.map<int>((e) => e['item_id'] as int).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    /// ✅ FIRST: availability filter
    final availableItems = widget.items.where((item) {
      return !unavailableItemIds.contains(item['id']);
    }).toList();

    /// ✅ THEN your existing search + category filter
    final filtered = availableItems.where((it) {
      final name = (it['name'] ?? '').toString().toLowerCase();
      final owner = (it['owner']?['full_name'] ?? '').toString().toLowerCase();
      final category = (it['category'] ?? '').toString().toLowerCase();
      final q = _query.toLowerCase();

      final match =
          name.contains(q) || owner.contains(q) || category.contains(q);
      final matchCategory =
          _categoryFilter == 'All' || it['category'] == _categoryFilter;

      return match && matchCategory;
    }).toList();

    /// ✅ KEEP YOUR SORT LOGIC (unchanged)
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
        final ta =
            DateTime.tryParse(a['createdAt'] ?? a['created_at'] ?? '') ??
            DateTime(2000);
        final tb =
            DateTime.tryParse(b['createdAt'] ?? b['created_at'] ?? '') ??
            DateTime(2000);
        return tb.compareTo(ta);
      });
    }

    /// 🔽 EVERYTHING BELOW IS YOUR ORIGINAL UI (UNCHANGED)
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
            /// SEARCH + SORT (UNCHANGED)
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

            /// CATEGORY CHIPS (UNCHANGED)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.categories.map((cat) {
                  final selected = _categoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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

            /// ITEM LIST (UNCHANGED)
            Expanded(
              child: sorted.isEmpty
                  ? const Center(child: Text('No matching items found 🔍'))
                  : ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, i) {
                        final item = sorted[i];
                        final originalIndex = widget.items.indexOf(item);

                        final isOwner =
                            item['owner_id'] ==
                            Supabase.instance.client.auth.currentUser?.id;

                        List<String> normalizeImages(dynamic raw) {
                          if (raw == null) return [];
                          if (raw is List) {
                            return raw.whereType<String>().toList();
                          }
                          if (raw is String) {
                            final s = raw.trim();
                            if (s.startsWith('[')) {
                              try {
                                final decoded = jsonDecode(s);
                                if (decoded is List) {
                                  return decoded.whereType<String>().toList();
                                }
                              } catch (_) {}
                            }
                            if (s.startsWith('http')) return [s];
                          }
                          return [];
                        }

                        final images = normalizeImages(item['images']);
                        final thumb = images.isNotEmpty ? images.first : null;

                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailPage(
                                item: Map<String, dynamic>.from(item),
                                index: originalIndex,
                                currentUser: widget.currentUser,
                                onUpdate: widget.onUpdate,
                                onDelete: widget.onDelete,
                              ),
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              leading: thumb != null
                                  ? Image.network(
                                      thumb,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.inventory_2),
                              title: Text(item['name'] ?? ''),
                              subtitle: Text('Rs ${item['price']}'),
                              trailing: ElevatedButton(
                                onPressed: isOwner
                                    ? null
                                    : () async {
                                        final booked = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookingPage(
                                              item: Map<String, dynamic>.from(
                                                item,
                                              ),
                                              index: originalIndex,
                                              currentUser: widget.currentUser,
                                              onUpdate: widget.onUpdate,
                                              allItems: widget.items,
                                            ),
                                          ),
                                        );

                                        /// 🔥 INSTANT REFRESH
                                        if (booked == true) {
                                          _loadUnavailableItems();
                                        }
                                      },
                                child: Text(isOwner ? 'Owned' : 'Book'),
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
