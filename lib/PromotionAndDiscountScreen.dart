import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'Calender.dart';

class PromotionAndDiscountScreen extends StatefulWidget {
  const PromotionAndDiscountScreen({super.key});

  @override
  State<PromotionAndDiscountScreen> createState() => _PromotionAndDiscountScreenState();
}

class _PromotionAndDiscountScreenState extends State<PromotionAndDiscountScreen> {
  final user = FirebaseAuth.instance.currentUser;
  DateTime? startDate;
  DateTime? endDate;
  String selectedDiscountType = 'Select Discount Type';
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _discountNameController = TextEditingController();
  final TextEditingController _discountTypeController = TextEditingController();
  final GlobalKey _discountTypeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _discountTypeController.text = selectedDiscountType;
  }

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _hideDropdown();
      return;
    }
    final RenderBox renderBox = _discountTypeKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(0, size.height + 8),
              child: Material(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Flat Off', 'Percentage Discount']
                        .map((String value) => ListTile(
                              title: Text(
                                value,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedDiscountType = value;
                                  _discountTypeController.text = value;
                                });
                                _hideDropdown();
                              },
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideDropdown();
    _discountNameController.dispose();
    _discountTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return CustomDatePickerDialog(
          initialDate: isStartDate ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _createNewDiscount() async {
    if (user == null || _discountNameController.text.isEmpty || selectedDiscountType == 'Select Discount Type' || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final discountData = {
      'name': _discountNameController.text,
      'type': selectedDiscountType,
      'startDate': Timestamp.fromDate(startDate!),
      'endDate': Timestamp.fromDate(endDate!),
      'isActive': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(user!.uid)
        .collection('RestaurantDetails')
        .doc(user!.uid)
        .collection('discounts')
        .add(discountData);

    setState(() {
      _discountNameController.clear();
      selectedDiscountType = 'Select Discount Type';
      _discountTypeController.text = selectedDiscountType;
      startDate = null;
      endDate = null;
    });
  }

  Future<void> _deleteDiscount(String docId) async {
    await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(user!.uid)
        .collection('RestaurantDetails')
        .doc(user!.uid)
        .collection('discounts')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leadingWidth: 40,
        titleSpacing: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeWidget()),
            );
          },
        ),
        title: Text(
          'Add Discount',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user?.uid)
            .collection('RestaurantDetails')
            .doc(user?.uid)
            .collection('discounts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading discounts'));
          }
          if (!snapshot.hasData) {
            return Center(
              child: LoadingAnimationWidget.discreteCircle(
                color: const Color(0xFF1B6FF5),
                size: 50,
              ),
            );
          }

          final discounts = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discount Name',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _discountNameController,
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          hintText: 'e.g. 20% Off First Order',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Discount Type',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CompositedTransformTarget(
                        link: _layerLink,
                        child: TextField(
                          key: _discountTypeKey,
                          controller: _discountTypeController,
                          readOnly: true,
                          cursorColor: Colors.black,
                          onTap: _toggleDropdown,
                          decoration: InputDecoration(
                            hintText: 'Select Discount Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SvgPicture.asset(
                                'assets/images/angle-small-down.svg',
                                width: 12, // Reduced from 16
                                height: 12, // Reduced from 16
                              ),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Validity Period',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                hintText: startDate == null ? 'MM/DD/YY' : DateFormat('MM/dd/yy').format(startDate!),
                                hintStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: const Icon(Icons.calendar_today, size: 20),
                              ),
                              style: const TextStyle(fontFamily: 'Poppins'),
                              onTap: () async {
                                await _selectDate(isStartDate: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                hintText: endDate == null ? 'MM/DD/YY' : DateFormat('MM/dd/yy').format(endDate!),
                                hintStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: const Icon(Icons.calendar_today, size: 20),
                              ),
                              style: const TextStyle(fontFamily: 'Poppins'),
                              onTap: () async {
                                await _selectDate(isStartDate: false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (discounts.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 500,
                    child: Center(
                      child: Text(
                        'No promotional discount available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BAUHAUSM',
                          fontSize: 25,
                          color: const Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: discounts.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] as String;
                      final startDate = (data['startDate'] as Timestamp).toDate();
                      final endDate = (data['endDate'] as Timestamp).toDate();
                      final isActive = data['isActive'] as bool;
                      final isExpired = DateTime.now().isAfter(endDate);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCCCC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: SvgPicture.asset(
                              'assets/images/trash.svg',
                              width: 28,
                              height: 28,
                              color: const Color(0xFFDA1313),
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: const Color(0xFFFFFFFF),
                                  title: const Text(
                                    'Confirm Delete',
                                    style: TextStyle(
                                      fontFamily: 'BAUHAUSM',
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this discount?',
                                    style: TextStyle(
                                      fontFamily:'BAUHAUSM',
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontFamily: 'BAUHAUSM',
                                          fontSize: 16,
                                          color: Color(0xFF1B6FF5),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontFamily: 'BAUHAUSM',
                                          fontSize: 16,
                                          color: Color(0xFFDA1313),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            _deleteDiscount(doc.id);
                          },
                          child: _buildPromotionCard(
                            title: name,
                            validity: 'Valid until ${DateFormat('MM/dd/yyyy').format(endDate)}',
                            isActive: isActive,
                            isExpired: isExpired,
                            onChanged: isExpired
                                ? null
                                : (value) {
                                    FirebaseFirestore.instance
                                        .collection('RestaurantUsers')
                                        .doc(user!.uid)
                                        .collection('RestaurantDetails')
                                        .doc(user!.uid)
                                        .collection('discounts')
                                        .doc(doc.id)
                                        .update({'isActive': value});
                                  },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _createNewDiscount,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B6FF5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Create New Discount',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionCard({
    required String title,
    required String validity,
    required bool isActive,
    bool isExpired = false,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    validity,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isExpired ? Colors.red : Colors.grey,
                    ),
                  ),
                  if (isExpired) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'EXPIRED',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (!isExpired)
            CustomToggleSwitch(
              value: isActive,
              onChanged: onChanged!,
            ),
        ],
      ),
    );
  }
}

class CustomToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: value ? const Color(0xFF1B6FF5) : Colors.grey.shade200,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class CustomDatePickerDialog extends StatefulWidget {
//   final DateTime initialDate;
//   final DateTime firstDate;
//   final DateTime lastDate;
//
//   const CustomDatePickerDialog({
//     super.key,
//     required this.initialDate,
//     required this.firstDate,
//     required this.lastDate,
//   });
//
//   @override
//   _CustomDatePickerDialogState createState() => _CustomDatePickerDialogState();
// }
//
// class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
//   late DateTime _selectedDate;
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = widget.initialDate;
//   }
//
//   void _previousMonth() {
//     setState(() {
//       final newMonth = _selectedDate.month - 1;
//       final newYear = newMonth == 0 ? _selectedDate.year - 1 : _selectedDate.year;
//       _selectedDate = DateTime(
//         newMonth == 0 ? newYear : _selectedDate.year,
//         newMonth == 0 ? 12 : newMonth,
//         1,
//       );
//     });
//   }
//
//   void _nextMonth() {
//     setState(() {
//       final newMonth = _selectedDate.month + 1;
//       final newYear = newMonth == 13 ? _selectedDate.year + 1 : _selectedDate.year;
//       _selectedDate = DateTime(
//         newMonth == 13 ? newYear : _selectedDate.year,
//         newMonth == 13 ? 1 : newMonth,
//         1,
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
//     final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
//     final firstDayWeekday = firstDayOfMonth.weekday % 7; // Sunday start (0 = Sunday)
//
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Container(
//         width: 300,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//               color: const Color(0xFF26A69A), // Changed to match app theme
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         DateFormat('EEEE').format(_selectedDate),
//                         style: const TextStyle(
//                           fontFamily: 'BAUHAUSM',
//                           fontSize: 14,
//                           color: Colors.white,
//                         ),
//                       ),
//                       Text(
//                         DateFormat('MMM dd').format(_selectedDate).toUpperCase(),
//                         style: const TextStyle(
//                           fontFamily: 'BAUHAUSM',
//                           fontSize: 32,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         DateFormat('yyyy').format(_selectedDate),
//                         style: const TextStyle(
//                           fontFamily: 'BAUHAUSM',
//                           fontSize: 14,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_drop_up, color: Colors.white),
//                         onPressed: _previousMonth,
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
//                         onPressed: _nextMonth,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
//                 return Text(
//                   day,
//                   style: const TextStyle(
//                     fontFamily: 'BAUHAUSM',
//                     fontSize: 14,
//                     color: Colors.black,
//                   ),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 8),
//             GridView.count(
//               shrinkWrap: true,
//               crossAxisCount: 7,
//               childAspectRatio: 1,
//               children: List.generate(firstDayWeekday, (index) => const SizedBox())
//                 ..addAll(List.generate(daysInMonth, (index) {
//                   final day = index + 1;
//                   final date = DateTime(_selectedDate.year, _selectedDate.month, day);
//                   final isSelected = _selectedDate.day == day &&
//                       _selectedDate.month == date.month &&
//                       _selectedDate.year == date.year;
//                   final isDisabled = date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);
//
//                   return GestureDetector(
//                     onTap: isDisabled
//                         ? null
//                         : () {
//                             setState(() {
//                               _selectedDate = date;
//                             });
//                           },
//                     child: Container(
//                       margin: const EdgeInsets.all(2),
//                       decoration: BoxDecoration(
//                         color: isSelected ? const Color(0xFF26A69A) : Colors.transparent,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           day.toString(),
//                           style: TextStyle(
//                             fontFamily: 'BAUHAUSM',
//                             fontSize: 14,
//                             color: isSelected
//                                 ? Colors.white
//                                 : isDisabled
//                                     ? Colors.grey
//                                     : Colors.black,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 })),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: const Text(
//                     'CANCEL',
//                     style: TextStyle(
//                       fontFamily: 'BAUHAUSM',
//                       fontSize: 14,
//                       color: Color(0xFF26A69A),
//                     ),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context, _selectedDate);
//                   },
//                   child: const Text(
//                     'OK',
//                     style: TextStyle(
//                       fontFamily: 'BAUHAUSM',
//                       fontSize: 14,
//                       color: Color(0xFF26A69A),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

void main() {
  runApp(const MaterialApp(
    home: PromotionAndDiscountScreen(),
  ));
}