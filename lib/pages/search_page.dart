import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'item_detail_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'my_rentals_page.dart';

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
                                              : () async {
                                                  // Custom dialog: only allow picking within two months from today
                                                  final now = DateTime.now();
                                                  final firstDate = DateTime(
                                                    now.year,
                                                    now.month,
                                                    1,
                                                  );
                                                  final lastDate = DateTime(
                                                    now.year,
                                                    now.month + 2,
                                                    0,
                                                  ); // end of next month
                                                  // using fresh dialog-local range state
                                                  // Replace with a richer two-month dialog (start/end chips + live total)
                                                  final pickedRange = await showDialog<DateTimeRange?>(
                                                    context: context,
                                                    builder: (context) {
                                                      DateTime? rangeStart;
                                                      DateTime? rangeEnd;

                                                      return StatefulBuilder(
                                                        builder: (context, setDialogState) {
                                                          double
                                                          computeTotal() {
                                                            if (rangeStart ==
                                                                    null ||
                                                                rangeEnd ==
                                                                    null) {
                                                              return 0;
                                                            }
                                                            final days =
                                                                rangeEnd!
                                                                    .difference(
                                                                      rangeStart!,
                                                                    )
                                                                    .inDays +
                                                                1;
                                                            return pricePerDay *
                                                                days;
                                                          }

                                                          final maxDialogHeight =
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.height *
                                                              0.75;
                                                          final calendarHeight =
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.height *
                                                              0.45;

                                                          return AlertDialog(
                                                            title: const Text(
                                                              'Select rental period',
                                                            ),
                                                            content: ConstrainedBox(
                                                              constraints:
                                                                  BoxConstraints(
                                                                    maxWidth:
                                                                        520,
                                                                    maxHeight:
                                                                        maxDialogHeight,
                                                                  ),
                                                              child: SingleChildScrollView(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    SizedBox(
                                                                      height: calendarHeight
                                                                          .clamp(
                                                                            180.0,
                                                                            320.0,
                                                                          ),
                                                                      child: CalendarDatePicker(
                                                                        initialDate:
                                                                            rangeStart ??
                                                                            firstDate,
                                                                        firstDate:
                                                                            firstDate,
                                                                        lastDate:
                                                                            lastDate,
                                                                        currentDate:
                                                                            now,
                                                                        onDateChanged:
                                                                            (
                                                                              selected,
                                                                            ) {
                                                                              setDialogState(
                                                                                () {
                                                                                  if (rangeStart ==
                                                                                          null ||
                                                                                      (rangeStart !=
                                                                                              null &&
                                                                                          rangeEnd !=
                                                                                              null)) {
                                                                                    rangeStart = selected;
                                                                                    rangeEnd = null;
                                                                                  } else if (rangeStart !=
                                                                                          null &&
                                                                                      rangeEnd ==
                                                                                          null) {
                                                                                    if (selected.isBefore(
                                                                                      rangeStart!,
                                                                                    )) {
                                                                                      rangeStart = selected;
                                                                                    } else {
                                                                                      rangeEnd = selected;
                                                                                    }
                                                                                  }
                                                                                },
                                                                              );
                                                                            },
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          12,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: Wrap(
                                                                            spacing:
                                                                                8,
                                                                            children: [
                                                                              InputChip(
                                                                                label: Text(
                                                                                  rangeStart ==
                                                                                          null
                                                                                      ? 'Start date'
                                                                                      : '${rangeStart!.day}/${rangeStart!.month}/${rangeStart!.year}',
                                                                                ),
                                                                                avatar: const Icon(
                                                                                  Icons.calendar_today,
                                                                                  size: 18,
                                                                                ),
                                                                                onPressed: () => setDialogState(
                                                                                  () {
                                                                                    rangeStart = null;
                                                                                    rangeEnd = null;
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              InputChip(
                                                                                label: Text(
                                                                                  rangeEnd ==
                                                                                          null
                                                                                      ? 'End date'
                                                                                      : '${rangeEnd!.day}/${rangeEnd!.month}/${rangeEnd!.year}',
                                                                                ),
                                                                                avatar: const Icon(
                                                                                  Icons.calendar_today,
                                                                                  size: 18,
                                                                                ),
                                                                                onPressed: () => setDialogState(
                                                                                  () {
                                                                                    rangeEnd = null;
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              if (rangeStart !=
                                                                                      null &&
                                                                                  rangeEnd !=
                                                                                      null)
                                                                                Chip(
                                                                                  label: Text(
                                                                                    '${rangeEnd!.difference(rangeStart!).inDays + 1} day(s)',
                                                                                  ),
                                                                                ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          12,
                                                                    ),
                                                                    Container(
                                                                      width: double
                                                                          .infinity,
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            12,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(
                                                                          0xFFEDF7FF,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              10,
                                                                            ),
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          SvgPicture.asset(
                                                                            'assets/icons/nepali_rupee_filled.svg',
                                                                            width:
                                                                                28,
                                                                            height:
                                                                                28,
                                                                            colorFilter: const ColorFilter.mode(
                                                                              Color(
                                                                                0xFF1E88E5,
                                                                              ),
                                                                              BlendMode.srcIn,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                8,
                                                                          ),
                                                                          Expanded(
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  rangeStart !=
                                                                                              null &&
                                                                                          rangeEnd !=
                                                                                              null
                                                                                      ? 'Total for ${rangeEnd!.difference(rangeStart!).inDays + 1} day(s)'
                                                                                      : 'Select dates to see total',
                                                                                  style: const TextStyle(
                                                                                    fontWeight: FontWeight.w600,
                                                                                    fontSize: 14,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  height: 4,
                                                                                ),
                                                                                Text(
                                                                                  rangeStart !=
                                                                                              null &&
                                                                                          rangeEnd !=
                                                                                              null
                                                                                      ? 'Rs ${computeTotal().toStringAsFixed(2)}'
                                                                                      : '—',
                                                                                  style: const TextStyle(
                                                                                    color: Color(
                                                                                      0xFF1E88E5,
                                                                                    ),
                                                                                    fontSize: 16,
                                                                                    fontWeight: FontWeight.w800,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      null,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      const Color(
                                                                        0xFF43A047,
                                                                      ),
                                                                ),
                                                                onPressed:
                                                                    (rangeStart !=
                                                                            null &&
                                                                        rangeEnd !=
                                                                            null)
                                                                    ? () => Navigator.pop(
                                                                        context,
                                                                        DateTimeRange(
                                                                          start:
                                                                              rangeStart!,
                                                                          end:
                                                                              rangeEnd!,
                                                                        ),
                                                                      )
                                                                    : null,
                                                                child: const Padding(
                                                                  padding: EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12.0,
                                                                    vertical:
                                                                        8.0,
                                                                  ),
                                                                  child: Text(
                                                                    'Book',
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );

                                                  if (pickedRange
                                                      is DateTimeRange) {
                                                    setState(() {
                                                      _selectedRange =
                                                          pickedRange;
                                                      _selectedIndex = i;
                                                      _liveTotal =
                                                          pricePerDay *
                                                          (pickedRange.end
                                                                  .difference(
                                                                    pickedRange
                                                                        .start,
                                                                  )
                                                                  .inDays +
                                                              1);
                                                    });
                                                    final updated =
                                                        Map<
                                                          String,
                                                          dynamic
                                                        >.from(item);
                                                    updated['rentedBy'] =
                                                        widget.currentUser;
                                                    updated['status'] =
                                                        'pending';
                                                    updated['rentedAt'] =
                                                        DateTime.now()
                                                            .toIso8601String();
                                                    updated['rentedFrom'] =
                                                        pickedRange.start
                                                            .toIso8601String();
                                                    updated['rentedTo'] =
                                                        pickedRange.end
                                                            .toIso8601String();
                                                    widget.onUpdate(
                                                      originalIndex,
                                                      updated,
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Booking requested — Rs ${_liveTotal?.toStringAsFixed(2) ?? ''} (Pending)',
                                                        ),
                                                      ),
                                                    );
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            MyRentalsPage(
                                                              rentals:
                                                                  widget.items,
                                                            ),
                                                      ),
                                                    );
                                                  }
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
