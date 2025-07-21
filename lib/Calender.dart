import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color headerColor;
  final Color selectedColor;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.headerColor = const Color(0xFF26A69A),
    this.selectedColor = const Color(0xFF26A69A),
  });

  @override
  _CustomDatePickerDialogState createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  void _previousMonth() {
    setState(() {
      final newMonth = _selectedDate.month - 1;
      final newYear = newMonth == 0 ? _selectedDate.year - 1 : _selectedDate.year;
      _selectedDate = DateTime(
        newMonth == 0 ? newYear : _selectedDate.year,
        newMonth == 0 ? 12 : newMonth,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      final newMonth = _selectedDate.month + 1;
      final newYear = newMonth == 13 ? _selectedDate.year + 1 : _selectedDate.year;
      _selectedDate = DateTime(
        newMonth == 13 ? newYear : _selectedDate.year,
        newMonth == 13 ? 1 : newMonth,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Sunday start (0 = Sunday)

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              color: widget.headerColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selectedDate),
                        style: const TextStyle(
                          fontFamily: 'BAUHAUSM',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd').format(_selectedDate).toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'BAUHAUSM',
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontFamily: 'BAUHAUSM',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_up, color: Colors.white),
                        onPressed: _previousMonth,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Text(
                  day,
                  style: const TextStyle(
                    fontFamily: 'BAUHAUSM',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              childAspectRatio: 1,
              children: List.generate(firstDayWeekday, (index) => const SizedBox())
                ..addAll(List.generate(daysInMonth, (index) {
                  final day = index + 1;
                  final date = DateTime(_selectedDate.year, _selectedDate.month, day);
                  final isSelected = _selectedDate.day == day &&
                      _selectedDate.month == date.month &&
                      _selectedDate.year == date.year;
                  final isDisabled = date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected ? widget.selectedColor : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontFamily: 'BAUHAUSM',
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white
                                : isDisabled
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                })),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontFamily: 'BAUHAUSM',
                      fontSize: 14,
                      color: widget.selectedColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedDate);
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'BAUHAUSM',
                      fontSize: 14,
                      color: widget.selectedColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}