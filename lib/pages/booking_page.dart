import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'my_rentals_page.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String currentUser;
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
  DateTimeRange? _range;
  int _days = 0;
  double _total = 0;

  // Color palette
  final Color primary = const Color(0xFF1E88E5);
  final Color accent = const Color(0xFFFFC107);
  final Color bg = const Color(0xFFF5F7FA);
  final Color textDark = const Color(0xFF263238);

  double get _pricePerDay =>
      double.tryParse(widget.item['price']?.toString() ?? '') ?? 0;

  late final DateTime _today;
  late final DateTime _lastAllowed;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _lastAllowed = DateTime(_today.year, _today.month + 6, _today.day);
  }

  void _onRangeChanged(DateTimeRange? r) {
    setState(() {
      _range = r;
      if (r == null) {
        _days = 0;
        _total = 0;
      } else {
        _days = r.end.difference(r.start).inDays + 1;
        _total = _days * _pricePerDay;
      }
    });
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirmBooking() async {
    if (_range == null) return;

    final updated = Map<String, dynamic>.from(widget.item);
    updated['status'] = 'Booked';
    updated['rentedBy'] = widget.currentUser;
    updated['rentedAt'] = DateTime.now().toIso8601String();
    updated['bookingFrom'] = _range!.start.toIso8601String();
    updated['bookingTo'] = _range!.end.toIso8601String();

    widget.onUpdate(widget.index, updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking confirmed — Total Rs ${_total.toStringAsFixed(2)}',
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    final rentals = widget.allItems
        .where((it) => it['rentedBy'] != null)
        .toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MyRentalsPage(rentals: rentals)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.item['image'] as String?;

    Widget itemImage = const SizedBox.shrink();
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        itemImage = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 96, height: 72, fit: BoxFit.cover),
        );
      }
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Confirm Booking"),
        backgroundColor: primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.85)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    itemImage,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item['name'] ?? "Item",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Rs ${widget.item['price']} / day",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Calendar card
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _range == null
                                    ? "Select your date range"
                                    : "${_fmt(_range!.start)} → ${_fmt(_range!.end)} ($_days days)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: DualMonthCalendar(
                            firstDate: _today,
                            lastDate: _lastAllowed,
                            initialStartVisibleMonth: DateTime(
                              _today.year,
                              _today.month,
                              1,
                            ),
                            primaryColor: primary,
                            accentColor: accent,
                            onRangeSelected: _onRangeChanged,
                            selectedRange: _range,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Summary
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rental Summary",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text("Days: $_days"),
                            Text(
                              "Price/day: Rs ${_pricePerDay.toStringAsFixed(2)}",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(color: Colors.black54),
                          ),
                          Text(
                            "Rs ${_total.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_range == null || _days == 0)
                          ? null
                          : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _range == null
                            ? "Select Dates"
                            : "Confirm — Rs ${_total.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
    );
  }
}

/// Dual Month Calendar with range selection
class DualMonthCalendar extends StatefulWidget {
  final DateTime initialStartVisibleMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?> onRangeSelected;
  final Color primaryColor;
  final Color accentColor;

  const DualMonthCalendar({
    super.key,
    required this.initialStartVisibleMonth,
    required this.firstDate,
    required this.lastDate,
    required this.onRangeSelected,
    required this.primaryColor,
    required this.accentColor,
    this.selectedRange,
  });

  @override
  State<DualMonthCalendar> createState() => _DualMonthCalendarState();
}

class _DualMonthCalendarState extends State<DualMonthCalendar> {
  late DateTime _leftMonth;
  DateTimeRange? _tempRange;
  bool _selectingStart = true;

  @override
  void initState() {
    super.initState();
    _leftMonth = DateTime(
      widget.initialStartVisibleMonth.year,
      widget.initialStartVisibleMonth.month,
      1,
    );
    _tempRange = widget.selectedRange;
  }

  void _moveMonths(int months) {
    final newLeft = DateTime(_leftMonth.year, _leftMonth.month + months, 1);
    if (newLeft.isBefore(widget.firstDate)) return;
    if (newLeft.isAfter(widget.lastDate.subtract(const Duration(days: 1)))) {
      return;
    }
    setState(() => _leftMonth = newLeft);
  }

  bool _isDisabled(DateTime d) =>
      d.isBefore(widget.firstDate) || d.isAfter(widget.lastDate);

  void _onDayTap(DateTime tapped) {
    if (_isDisabled(tapped)) return;

    setState(() {
      if (_tempRange == null || !_selectingStart) {
        _tempRange = DateTimeRange(start: tapped, end: tapped);
        _selectingStart = false;
      } else {
        final start = _tempRange!.start;
        if (tapped.isBefore(start)) {
          _tempRange = DateTimeRange(start: tapped, end: start);
        } else {
          _tempRange = DateTimeRange(start: start, end: tapped);
        }
        _selectingStart = true;
      }

      widget.onRangeSelected(_tempRange);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rightMonth = DateTime(_leftMonth.year, _leftMonth.month + 1, 1);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _moveMonths(-2),
              icon: Icon(Icons.chevron_left, color: widget.primaryColor),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "${_monthTitle(_leftMonth)}  —  ${_monthTitle(rightMonth)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _moveMonths(2),
              icon: Icon(Icons.chevron_right, color: widget.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildMonth(_leftMonth)),
              const SizedBox(width: 8),
              Expanded(child: _buildMonth(rightMonth)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(
      month.year,
      month.month + 1,
      1,
    ).subtract(const Duration(days: 1)).day;
    final startWeekday = first.weekday % 7;
    final totalCells = startWeekday + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    List<Widget> rows = [];

    // Weekday row
    rows.add(
      Row(
        children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    int dayNum = 1;
    for (int w = 0; w < weeks; w++) {
      List<Widget> week = [];
      for (int wd = 0; wd < 7; wd++) {
        final index = w * 7 + wd;
        if (index < startWeekday || dayNum > daysInMonth) {
          week.add(const Expanded(child: SizedBox()));
        } else {
          final dayDate = DateTime(month.year, month.month, dayNum);
          final disabled = _isDisabled(dayDate);

          final sel = _tempRange;
          final isStart = sel != null && _sameDay(sel.start, dayDate);
          final isEnd = sel != null && _sameDay(sel.end, dayDate);
          final inRange =
              sel != null &&
              !dayDate.isBefore(sel.start) &&
              !dayDate.isAfter(sel.end);

          week.add(
            Expanded(
              child: GestureDetector(
                onTap: disabled ? null : () => _onDayTap(dayDate),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  height: 34,
                  decoration: BoxDecoration(
                    color: isStart || isEnd
                        ? widget.primaryColor
                        : (inRange
                              ? widget.primaryColor.withOpacity(0.18)
                              : null),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "$dayNum",
                      style: TextStyle(
                        color: disabled
                            ? Colors.black26
                            : (isStart || isEnd
                                  ? Colors.white
                                  : Colors.black87),
                        fontWeight: isStart || isEnd
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          dayNum++;
        }
      }
      rows.add(Row(children: week));
    }

    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          _monthTitle(month),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Expanded(child: Column(children: rows)),
      ],
    );
  }

  String _monthTitle(DateTime m) {
    const months = [
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
    return "${months[m.month - 1]} ${m.year}";
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
