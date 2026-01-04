import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_rentals_page.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String? currentUser;
  final void Function(int, Map<String, dynamic>) onUpdate;
  final List<Map<String, dynamic>> allItems;

  const BookingPage({
    super.key,
    required this.item,
    required this.index,
    required this.currentUser,
    required this.onUpdate,
    required this.allItems,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? start;
  DateTime? end;

  final DateTime today = DateTime.now();
  int monthIndex = 0; // how many months ahead you're viewing

  double get pricePerDay =>
      double.tryParse(widget.item['price']?.toString() ?? "") ?? 0;

  int get totalDays {
    if (start == null || end == null) return 0;
    return end!.difference(start!).inDays + 1;
  }

  double get totalPrice => totalDays * pricePerDay;

  // 6-month limit
  DateTime getMonth(int add) {
    return DateTime(today.year, today.month + add, 1);
  }

  bool isWithinLimit(DateTime date) {
    DateTime maxDate = DateTime(today.year, today.month + 6, today.day);
    return date.isAfter(today.subtract(const Duration(days: 1))) &&
        date.isBefore(maxDate);
  }

  void selectDate(DateTime date) {
    if (!isWithinLimit(date)) return;

    setState(() {
      if (start == null || (start != null && end != null)) {
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

  Future<void> confirmBooking() async {
    // 🔐 AUTH CHECK (ADD THIS AT THE VERY TOP)
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue booking')),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      await Navigator.pushNamed(context, '/login');
      return;
    }

    if (start == null || end == null) return;

    final updated = Map<String, dynamic>.from(widget.item);
    updated['status'] = 'Pending';
    updated['rentedBy'] = widget.currentUser;
    updated['rentedAt'] = DateTime.now().toIso8601String();
    updated['bookingFrom'] = start!.toIso8601String();
    updated['bookingTo'] = end!.toIso8601String();

    widget.onUpdate(widget.index, updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Booking confirmed — Rs ${totalPrice.toStringAsFixed(2)}",
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 650));

    final rentals = widget.allItems
        .where((it) => it["rentedBy"] != null)
        .toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MyRentalsPage(rentals: rentals)),
    );
  }

  Future<void> bookItem(String itemId, String ownerId) async {
    final user = Supabase.instance.client.auth.currentUser!;

    await Supabase.instance.client.from('bookings').insert({
      'item_id': itemId,
      'owner_id': ownerId,
      'renter_id': user.id,
      'status': 'pending',
    });
  }

  @override
  Widget build(BuildContext context) {
    final month = getMonth(monthIndex);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekdayOffset = firstDay.weekday - 1;

    final imagePath = widget.item['image'];
    Widget thumbnail = const SizedBox.shrink();
    if (imagePath != null && File(imagePath).existsSync()) {
      thumbnail = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(imagePath),
          width: 90,
          height: 75,
          fit: BoxFit.cover,
        ),
      );
    }

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
              // ITEM CARD
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
                    thumbnail,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item['name'],
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
                            "Owner: ${widget.item['owner']}",
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

              // MONTH HEADER
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

              const SizedBox(height: 4),

              // WEEKDAYS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ["M", "T", "W", "T", "F", "S", "S"]
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 6),

              // CALENDAR GRID
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.36,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: daysInMonth + weekdayOffset,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemBuilder: (_, index) {
                    if (index < weekdayOffset) {
                      return const SizedBox.shrink();
                    }

                    final day = index - weekdayOffset + 1;
                    final date = DateTime(month.year, month.month, day);

                    final isSel = isSelected(date);
                    final isEnabled = isWithinLimit(date);

                    return GestureDetector(
                      onTap: isEnabled ? () => selectDate(date) : null,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF1E88E5)
                              : isEnabled
                              ? Colors.transparent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "$day",
                          style: TextStyle(
                            color: isSel
                                ? Colors.white
                                : const Color(0xFF263238),
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // PRICE BREAKDOWN
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

              // BUTTON
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
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
