import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// Replace with your actual import path for HomeWidget.
import 'home_screen.dart';

class OrderHistoryWidget extends StatefulWidget {
  const OrderHistoryWidget({super.key});

  @override
  State<OrderHistoryWidget> createState() => _OrderHistoryWidgetState();
}

class _OrderHistoryWidgetState extends State<OrderHistoryWidget> {
  late Stream<QuerySnapshot> _orderDetailsStream;
  DateTime? _selectedDate = DateTime.now(); // Default to current date

  @override
  void initState() {
    super.initState();
    _updateOrderStream();
  }

  void _updateOrderStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _orderDetailsStream = Stream<QuerySnapshot>.empty();
      return;
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(currentUser.uid)
        .collection('orderdetails')
        .orderBy('timestamp', descending: true);

    // Apply date filter (default to today if _selectedDate is not null)
    if (_selectedDate != null) {
      final startOfDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay));
    }

    _orderDetailsStream = query.snapshots();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return CustomDatePickerDialog(
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateOrderStream();
      });
    }
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return 'Select Date';
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    return isToday ? 'Today' : DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 40,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeWidget()),
              );
            },
          ),
          centerTitle: false,
          title: const Text(
            'Order History',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF1B6FF5),
                ),
                label: Text(
                  _formatDateDisplay(_selectedDate),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF1B6FF5),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _orderDetailsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.discreteCircle(
                  color: const Color(0xFF1B6FF5),
                  size: 50,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  _selectedDate == null
                      ? 'No orders have been picked up yet.'
                      : 'No orders found for ${_formatDateDisplay(_selectedDate)}.',
                  style: TextStyle(
                    fontSize: 23,
                    fontFamily: 'BAUHAUSM',
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }

            final orderDocs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: orderDocs.length,
              itemBuilder: (context, index) {
                final doc = orderDocs[index];
                final data = doc.data() as Map<String, dynamic>;

                final Timestamp? ts = data['timestamp'];
                final DateTime orderDate =
                    ts != null ? ts.toDate() : DateTime.now();
                final formattedDateTime =
                    DateFormat('MMM dd, yyyy • hh:mm a').format(orderDate);

                final totalBill = data['totalBill'];
                double totalBillValue = 0.0;
                if (totalBill is num) {
                  totalBillValue = totalBill.toDouble();
                } else if (totalBill is String) {
                  totalBillValue = double.tryParse(totalBill) ?? 0.0;
                }
                final totalAmount = "₹${totalBillValue.toStringAsFixed(2)}";

                final Timestamp? pickupTs = data['pickupTime'];
                final pickupTime = pickupTs != null
                    ? DateFormat('hh:mm a').format(pickupTs.toDate())
                    : 'N/A';

                final List<dynamic> dishes = data['dishes'] ?? [];
                List<Map<String, String>> itemsList = [];
                for (var dish in dishes) {
                  final dishMap = dish as Map<String, dynamic>;
                  final name = dishMap['name'] ?? 'N/A';
                  int quantity = 1;
                  final dynamic qtyData = dishMap['quantity'];
                  if (qtyData is int) {
                    quantity = qtyData;
                  } else if (qtyData is String) {
                    quantity = int.tryParse(qtyData) ?? 1;
                  }
                  double pricePerItem = 0.0;
                  final dynamic priceData = dishMap['price'];
                  if (priceData is num) {
                    pricePerItem = priceData.toDouble();
                  } else if (priceData is String) {
                    pricePerItem = double.tryParse(priceData) ?? 0.0;
                  }
                  final double totalDishPrice = pricePerItem * quantity;

                  itemsList.add({
                    'name': '$name × $quantity',
                    'price': "₹${totalDishPrice.toStringAsFixed(2)}",
                  });
                }

                return _buildOrderCard(
                  orderId: doc.id,
                  dateTime: formattedDateTime,
                  items: itemsList,
                  totalAmount: totalAmount,
                  pickUpTime: 'Picked up at $pickupTime',
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String dateTime,
    required List<Map<String, String>> items,
    required String totalAmount,
    required String pickUpTime,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                dateTime,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item['name']!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item['price']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                totalAmount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B6FF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pickUpTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
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
      final newYear =
          newMonth == 0 ? _selectedDate.year - 1 : _selectedDate.year;
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
      final newYear =
          newMonth == 13 ? _selectedDate.year + 1 : _selectedDate.year;
      _selectedDate = DateTime(
        newMonth == 13 ? newYear : _selectedDate.year,
        newMonth == 13 ? 1 : newMonth,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    final firstDayWeekday =
        firstDayOfMonth.weekday % 7; // Adjust for Sunday start (0 = Sunday)

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
              color: const Color(0xFF26A69A),
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
                        DateFormat('MMM dd')
                            .format(_selectedDate)
                            .toUpperCase(),
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
                        icon: const Icon(Icons.arrow_drop_up,
                            color: Colors.white),
                        onPressed: _previousMonth,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
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
              children: List.generate(
                  firstDayWeekday, (index) => const SizedBox())
                ..addAll(List.generate(daysInMonth, (index) {
                  final day = index + 1;
                  final date =
                      DateTime(_selectedDate.year, _selectedDate.month, day);
                  final isSelected = _selectedDate.day == day &&
                      _selectedDate.month == date.month &&
                      _selectedDate.year == date.year;
                  final isDisabled = date.isBefore(widget.firstDate) ||
                      date.isAfter(widget.lastDate);

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
                        color: isSelected
                            ? const Color(0xFF26A69A)
                            : Colors.transparent,
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
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontFamily: 'BAUHAUSM',
                      fontSize: 14,
                      color: Color(0xFF26A69A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedDate);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'BAUHAUSM',
                      fontSize: 14,
                      color: Color(0xFF26A69A),
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

void main() {
  runApp(const OrderHistoryWidget());
}
