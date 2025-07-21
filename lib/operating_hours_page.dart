import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'profile_page.dart';

/// Simple model class for a time slot.
class TimeSlot {
  TimeOfDay opening;
  TimeOfDay closing;

  TimeSlot({required this.opening, required this.closing});
}

class OperatingHoursPage extends StatefulWidget {
  const OperatingHoursPage({super.key});

  @override
  _OperatingHoursPageState createState() => _OperatingHoursPageState();
}

class _OperatingHoursPageState extends State<OperatingHoursPage> {
  /// Maintain a list of time slots.
  final List<TimeSlot> _timeSlots = [
    TimeSlot(
      opening: const TimeOfDay(hour: 9, minute: 0),
      closing: const TimeOfDay(hour: 17, minute: 0),
    ),
  ];

  /// Adds a new time slot.
  void _addTimeSlot() {
    setState(() {
      _timeSlots.add(
        TimeSlot(
          opening: const TimeOfDay(hour: 9, minute: 0),
          closing: const TimeOfDay(hour: 17, minute: 0),
        ),
      );
    });
  }

  /// Deletes a time slot if there is more than one slot.
  void _deleteTimeSlot(int index) {
    if (_timeSlots.length > 1) {
      setState(() {
        _timeSlots.removeAt(index);
      });
    }
  }

  /// Helper: Convert TimeOfDay -> DateTime for CupertinoDatePicker.
  DateTime _dateTimeFromTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  /// Helper: Convert DateTime -> TimeOfDay after user picks a time.
  TimeOfDay _timeOfDayFromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  /// Helper: Returns the weekday string for a given weekday number.
  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  /// Show the Cupertino time picker in a centered dialog.
  void _showCupertinoTimePicker({
    required int index,
    required bool isOpening,
  }) {
    // Current time for the slot:
    final currentTime = isOpening
        ? _dateTimeFromTimeOfDay(_timeSlots[index].opening)
        : _dateTimeFromTimeOfDay(_timeSlots[index].closing);

    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Material(
            // Use Material to allow the dialog to have rounded corners and shadows.
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    textStyle: const TextStyle(fontFamily: 'BAUHAUSM'),
                    dateTimePickerTextStyle:
                        const TextStyle(fontFamily: 'BAUHAUSM'),
                  ),
                ),
                child: Column(
                  children: [
                    // Done button row.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: const Color(0xFF1B6FF5),
                              fontFamily: 'BAUHAUSM',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Cupertino time picker.
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: currentTime,
                        use24hFormat:
                            false, // set to true if you want 24h format
                        onDateTimeChanged: (DateTime newDateTime) {
                          setState(() {
                            if (isOpening) {
                              _timeSlots[index].opening =
                                  _timeOfDayFromDateTime(newDateTime);
                            } else {
                              _timeSlots[index].closing =
                                  _timeOfDayFromDateTime(newDateTime);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Formats TimeOfDay to a user-friendly string (e.g., 09:00 AM).
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    // Get the current weekday string.
    final String currentWeekday = _getWeekdayString(DateTime.now().weekday);

    return Scaffold(
      /// White background.
      backgroundColor: Colors.white,

      /// AppBar.
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 40,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Navigate back to ProfilePage.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
        title: const Text(
          'Business Hours',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),

      /// Body content.
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: ListView(
          children: [
            Text(
              currentWeekday,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Set your business hours for today',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            /// Render each time slot in a container.
            ..._timeSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// Top row: Time Slot label + delete icon.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Time Slot ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          // Disable if there is only one slot.
                          onPressed: _timeSlots.length > 1
                              ? () => _deleteTimeSlot(index)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    /// Opening & Closing Time Rows.
                    Row(
                      children: [
                        /// Opening Time Column.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Opening Time',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _showCupertinoTimePicker(
                                  index: index,
                                  isOpening: true,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTimeOfDay(slot.opening),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        /// Closing Time Column.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Closing Time',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _showCupertinoTimePicker(
                                  index: index,
                                  isOpening: false,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTimeOfDay(slot.closing),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            /// Add Time Slot.
            ElevatedButton.icon(
              onPressed: _addTimeSlot,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add Time Slot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 80), // Extra space so content is scrollable.
          ],
        ),
      ),

      /// Bottom fixed buttons (Save Changes and Cancel).
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            /// Cancel Button.
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black, // text color.
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 16),

            /// Save Changes Button.
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Handle save action.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6FF5),
                  foregroundColor: Colors.white, // text color.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example main method to run the app.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Operating Hours Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const OperatingHoursPage(),
    );
  }
}
