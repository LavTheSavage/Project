import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String? currentUser;
  final void Function(int, Map<String, dynamic>) onUpdate;
  final List<Map<String, dynamic>> allItems;

  const BookingPage({
    super.key,
    required this.item,
    required this.currentUser,
    required this.onUpdate,
    required this.index,
    required this.allItems,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? start;
  DateTime? end;

  final DateTime today = DateTime.now();
  int monthIndex = 0;

  double get pricePerDay =>
      double.tryParse(widget.item['price']?.toString() ?? '0') ?? 0;

  int get totalDays {
    if (start == null || end == null) return 0;
    return end!.difference(start!).inDays + 1;
  }

  double get totalPrice => totalDays * pricePerDay;

  DateTime getMonth(int add) {
    return DateTime(today.year, today.month + add, 1);
  }

  bool isWithinLimit(DateTime date) {
    final maxDate = DateTime(today.year, today.month + 6, today.day);
    return date.isAfter(today.subtract(const Duration(days: 1))) &&
        date.isBefore(maxDate);
  }

  void selectDate(DateTime date) {
    if (!isWithinLimit(date)) return;

    setState(() {
      if (start == null || end != null) {
        start = date;
        end = null;
      } else if (date.isBefore(start!)) {
        start = date;
      } else {
        end = date;
      }
    });
  }

  bool isSelected(DateTime date) {
    if (start == null) return false;
    if (end == null) return date == start;
    return date.isAfter(start!.subtract(const Duration(days: 1))) &&
        date.isBefore(end!.add(const Duration(days: 1)));
  }

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
      if (s.startsWith('http')) {
        return [s];
      }
    }

    return [];
  }

  Future<void> confirmBooking() async {
    if (widget.currentUser == null || start == null || end == null) return;

    final existing = await Supabase.instance.client
        .from('bookings')
        .select('id')
        .eq('item_id', widget.item['id'])
        .eq('renter_id', widget.currentUser)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already requested this item')),
      );
      return;
    }

    await Supabase.instance.client
        .from('bookings')
        .insert({
          'item_id': widget.item['id'],
          'owner_id': widget.item['owner_id'],
          'renter_id': widget.currentUser,
          'from_date': start!,
          'to_date': end!,
          'status': 'pending',
        })
        .select()
        .single();

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final month = getMonth(monthIndex);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekdayOffset = firstDay.weekday - 1;

    final images = normalizeImages(widget.item['images']);
    final thumb = images.isNotEmpty ? images.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Confirm Booking"),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 3,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              /// ITEM CARD
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: thumb != null
                          ? Image.network(
                              thumb,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.inventory_2),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rs ${widget.item['price']} / day",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Owner: ${widget.item['owner']?['full_name'] ?? '—'}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// MONTH HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: monthIndex == 0
                        ? null
                        : () => setState(() => monthIndex--),
                    icon: const Icon(Icons.chevron_left, size: 30),
                  ),
                  Text(
                    "${_monthName(month.month)} ${month.year}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  IconButton(
                    onPressed: monthIndex == 6
                        ? null
                        : () => setState(() => monthIndex++),
                    icon: const Icon(Icons.chevron_right, size: 30),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              /// WEEKDAYS
              Row(
                children: ["M", "T", "W", "T", "F", "S", "S"]
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 6),

              /// CALENDAR
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.36,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: daysInMonth + weekdayOffset,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemBuilder: (_, index) {
                    if (index < weekdayOffset) return const SizedBox.shrink();

                    final day = index - weekdayOffset + 1;
                    final date = DateTime(month.year, month.month, day);

                    final selected = isSelected(date);
                    final enabled = isWithinLimit(date);

                    return GestureDetector(
                      onTap: enabled ? () => selectDate(date) : null,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1E88E5)
                              : enabled
                              ? Colors.transparent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "$day",
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF263238),
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              /// PRICE SUMMARY
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _priceItem("Days", "$totalDays"),
                    const SizedBox(height: 6),
                    _priceItem(
                      "Price / day",
                      "Rs ${pricePerDay.toStringAsFixed(2)}",
                    ),
                    const Divider(height: 18),
                    _priceItem(
                      "Total",
                      "Rs ${totalPrice.toStringAsFixed(2)}",
                      bold: true,
                      color: const Color(0xFF1E88E5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// CONFIRM BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (start != null && end != null)
                      ? confirmBooking
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    (start != null && end != null)
                        ? "Confirm — Rs ${totalPrice.toStringAsFixed(0)}"
                        : "Select dates",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceItem(
    String key,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color ?? const Color(0xFF263238),
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const names = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return names[m];
  }
}
