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

const kPrimary = Color(0xFF1E88E5);
const kAccent = Color(0xFFFFC107);
const kBackground = Color(0xFFF5F7FA);
const kDark = Color(0xFF263238);
const kSecondary = Color(0xFF90CAF9);

class _SearchPageState extends State<SearchPage> {
  String _query = '';
  String _categoryFilter = 'All';
  String _sortBy = 'price_desc';

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items;

    final filtered = visibleItems.where((it) {
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

            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: widget.categories.map((cat) {
                  final selected = _categoryFilter == cat;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      selectedColor: kPrimary.withOpacity(0.15),
                      labelStyle: TextStyle(color: selected ? kPrimary : kDark),
                      onSelected: (_) {
                        setState(() {
                          _categoryFilter = cat;
                        });
                      },
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
                        final originalIndex = widget.items.indexWhere(
                          (e) => e['id'] == item['id'],
                        );
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
                                allItems: widget.items,
                              ),
                            ),
                          ),

                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// IMAGE
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: thumb != null && thumb.isNotEmpty
                                        ? Image.network(
                                            thumb,
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.inventory_2,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),

                                  const SizedBox(width: 12),

                                  /// DETAILS
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// ITEM NAME
                                        Text(
                                          item['name'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: kDark,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        /// LOCATION
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                item['location'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        /// OWNER
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              backgroundImage:
                                                  item['owner']?['avatar_url'] !=
                                                          null &&
                                                      item['owner']['avatar_url']
                                                          .toString()
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      item['owner']['avatar_url'],
                                                    )
                                                  : null,
                                              child:
                                                  item['owner']?['avatar'] ==
                                                          null ||
                                                      item['owner']['avatar']
                                                          .toString()
                                                          .isEmpty
                                                  ? const Icon(
                                                      Icons.person,
                                                      size: 14,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item['owner']?['full_name'] ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  /// PRICE + CTA
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kSecondary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Rs ${item['price'] ?? ''}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kAccent,
                                          foregroundColor: Colors.black,
                                          disabledBackgroundColor:
                                              Colors.grey.shade300,
                                          disabledForegroundColor:
                                              Colors.grey.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed: isOwner
                                            ? null
                                            : () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => BookingPage(
                                                      item:
                                                          Map<
                                                            String,
                                                            dynamic
                                                          >.from(item),
                                                      index: originalIndex,
                                                      currentUser:
                                                          widget.currentUser,
                                                      onUpdate: widget.onUpdate,
                                                      allItems: widget.items,
                                                    ),
                                                  ),
                                                );
                                              },
                                        child: Text(isOwner ? 'Owned' : 'Book'),
                                      ),
                                    ],
                                  ),
                                ],
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
