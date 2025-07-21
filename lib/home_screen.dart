import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'Calender.dart'; // Import the custom date picker

// Replace these with your actual imports/pages in your project:
import 'package:yammy_restaurent_partner/add_menu_item_screen.dart';
import 'package:yammy_restaurent_partner/analytics_screen.dart';
import 'package:yammy_restaurent_partner/profile_page.dart';
import 'package:yammy_restaurent_partner/inventoryItems.dart';
import 'package:yammy_restaurent_partner/ContactUsPage.dart';
import 'package:yammy_restaurent_partner/earning_screen.dart';
import 'package:yammy_restaurent_partner/PromotionAndDiscountScreen.dart';
import 'package:yammy_restaurent_partner/ordertime.dart';
import 'login.dart';

// Import OrderHistoryWidget, but hide CustomDatePickerDialog to avoid conflict
import 'package:yammy_restaurent_partner/Order_History.dart' hide CustomDatePickerDialog;

/// Simple data model for each order.
class OrderData {
  final String id;
  final String customerName;
  final String price;
  final String timeAgo;
  final String items;
  String status;

  OrderData({
    required this.id,
    required this.customerName,
    required this.price,
    required this.timeAgo,
    required this.items,
    required this.status,
  });
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedBottomIndex = 0;
  int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now(); // Made non-final to allow updates

  String _ownerName = 'Loading...';
  String _ownerEmail = 'Loading...';
  String _restaurantName = 'Loading...';
  String? _restaurantId;

  Stream<List<OrderData>>? _ordersStream;
  bool _isOnline = false;
  bool isFinished = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadCachedData();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOnline = prefs.getBool('isOnline') ?? false;
    });
    await Future.wait([
      _fetchRestaurantName(),
      _fetchOwnerDetails(),
    ]);
    _setupOrdersStream();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _restaurantName = prefs.getString('restaurantName') ?? 'Loading...';
      _ownerName = prefs.getString('ownerName') ?? 'Loading...';
      _ownerEmail = prefs.getString('ownerEmail') ?? 'Loading...';
    });
  }

  Future<void> _fetchRestaurantName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user.uid)
            .collection('RestaurantDetails')
            .doc(user.uid)
            .get();
        String restaurantName = doc.exists
            ? doc['restaurantName'] ?? 'No restaurant name found'
            : 'No restaurant name found';
        setState(() {
          _restaurantName = restaurantName;
          _restaurantId = user.uid;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('restaurantName', restaurantName);
      } else {
        setState(() {
          _restaurantName = 'User not authenticated';
        });
      }
    } catch (e) {
      print('Error fetching restaurant name: $e');
      setState(() {
        _restaurantName = 'Error fetching name';
      });
    }
  }

  Future<void> _fetchOwnerDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('RestaurantUsers')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw Exception('Firestore fetch timed out');
        });

        if (doc.exists) {
          String email = doc['email'] ?? 'No email found';
          String name = doc['name'] ?? 'No name found';

          setState(() {
            _ownerEmail = email;
            _ownerName = name;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ownerEmail', email);
          await prefs.setString('ownerName', name);
        } else {
          setState(() {
            _ownerEmail = 'No email found';
            _ownerName = 'No name found';
          });
        }
      } else {
        setState(() {
          _ownerEmail = 'User not authenticated';
          _ownerName = 'User not authenticated';
        });
      }
    } catch (e) {
      print('Error fetching owner details: $e');
      setState(() {
        _ownerEmail = 'Error fetching email';
        _ownerName = 'Error fetching name';
      });
    }
  }

  void _setupOrdersStream() {
    if (_restaurantId == null) return;

    // Define the start and end of the selected date
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    setState(() {
      _ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('restaurantId', isEqualTo: _restaurantId)
          .snapshots()
          .asyncMap((snapshot) async {
        List<OrderData> orders = [];
        for (var doc in snapshot.docs) {
          final order = await _mapFirestoreToOrderData(doc);
          if (order != null) {
            final orderTimestamp = (doc['timestamp'] as Timestamp).toDate();
            if (orderTimestamp.isAfter(startOfDay) && orderTimestamp.isBefore(endOfDay)) {
              orders.add(order);
            }
          }
        }
        return orders;
      });
    });
  }

  Future<OrderData?> _mapFirestoreToOrderData(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    if (data['restaurantId'] != _restaurantId) {
      return null;
    }

    final dishes = List<Map<String, dynamic>>.from(data['dishes'] ?? []);
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final userId = data['userId'] as String?;

    String customerName = 'Unknown Customer';
    if (userId != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          customerName = userDoc['name'] ?? 'Unknown Customer';
        }
      } catch (e) {
        print('Error fetching customer name: $e');
      }
    }

    String items = dishes.map((dish) {
      return '${dish['quantity']}x ${dish['name']}';
    }).join('\n');

    String timeDisplay;
    if (data['status'] == 'picked') {
      final Timestamp? pickupTs = data['pickupTime'];
      if (pickupTs != null) {
        timeDisplay = DateFormat('hh:mm a').format(pickupTs.toDate());
      } else {
        timeDisplay = 'Unknown pickup time';
      }
    } else {
      timeDisplay = _calculateTimeAgo(timestamp);
    }

    String status = data['status'] ?? 'placed';

    return OrderData(
      id: doc.id,
      customerName: customerName,
      price: '₹${(data['totalBill'] as num).toStringAsFixed(2)}',
      timeAgo: timeDisplay,
      items: items.isNotEmpty ? items : 'No items',
      status: status,
    );
  }

  String _calculateTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _formatSelectedDate(DateTime date) {
    final now = DateTime.now();
    final isToday = (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day);
    return isToday
        ? 'Today, ${DateFormat('MMMM d').format(date)}'
        : DateFormat('MMMM d').format(date);
  }

  void _navigateToProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  // Updated function to use CustomDatePickerDialog
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return CustomDatePickerDialog(
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          headerColor: const Color(0xFF1B6FF5), // Match HomeWidget theme
          selectedColor: const Color(0xFF1B6FF5), // Match HomeWidget theme
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _setupOrdersStream(); // Refresh the orders stream with the new date
    }
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
        key: _scaffoldKey,
        drawer: Drawer(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color(0xFF1B6FF5),
                        child: Text(
                          _ownerName.isNotEmpty ? _ownerName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ownerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis, // Prevent overflow for long names
                            ),
                            const SizedBox(height: 4), // Removed width property
                            Text(
                              _ownerEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis, // Prevent overflow for long emails
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  thickness: 1,
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                _buildMenuItem(
                  iconPath: 'assets/images/updateinventorym.svg',
                  title: 'Inventory Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InventoryPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: 'assets/images/discount.svg',
                  title: 'Promotions & Discounts',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const PromotionAndDiscountScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: 'assets/images/report.svg',
                  title: 'Reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AnalysisWidget()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: 'assets/images/star.svg',
                  title: 'Feedback & Reviews',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildMenuItem(
                  iconPath: 'assets/images/clock.svg',
                  title: 'Order History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderHistoryWidget()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: 'assets/images/customer-service.svg',
                  title: 'Contact Us',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ContactUsPage()),
                    );
                  },
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                        FirebaseAuth.instance.signOut();
                      },
                      child: const Text('Logout'),

                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          titleSpacing: 8.0,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          centerTitle: false,
          title: Text(
            _restaurantName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.black),
              onPressed: _navigateToProfile,
            ),
          ],
        ),
        body: _ordersStream == null
            ? Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: const Color(0xFF1B6FF5),
            size: 50,
          ),
        )
            : StreamBuilder<List<OrderData>>(
          stream: _ordersStream,
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
              // Check if the error is related to a missing index
              if (snapshot.error.toString().contains('requires an index')) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: This query requires a Firestore index. Please create the index in the Firebase console and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final orders = snapshot.data ?? [];
            List<OrderData> displayedOrders;
            String noOrdersText;

            if (_selectedTabIndex == 0) {
              displayedOrders = orders
                  .where((order) =>
              order.status == 'placed' ||
                  order.status == 'accepted')
                  .toList();
              noOrdersText = 'No orders to prepare now';
            } else if (_selectedTabIndex == 1) {
              displayedOrders = orders
                  .where((order) => order.status == 'ready')
                  .toList();
              noOrdersText = 'No orders are ready at the moment';
            } else if (_selectedTabIndex == 2) {
              displayedOrders = orders
                  .where((order) => order.status == 'picked')
                  .toList();
              noOrdersText = 'No items have been picked up yet';
            } else {
              displayedOrders = [];
              noOrdersText = 'No Recent Orders';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatSelectedDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/images/daily-calendar.svg',
                            width: 24,
                            height: 24,
                            color: Colors.black54,
                          ),
                          onPressed: _selectDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwipeableButtonView(
                    buttonText: _isOnline
                        ? 'Slide to go Offline'
                        : 'Slide to go Online',
                    buttonWidget: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                      ),
                    ),
                    activeColor: _isOnline ? Colors.green : Colors.grey,
                    isFinished: isFinished,
                    onWaitingProcess: () {
                      Future.delayed(const Duration(seconds: 2), () {
                        setState(() {
                          isFinished = true;
                        });
                      });
                    },
                    onFinish: () async {
                      setState(() {
                        _isOnline = !_isOnline;
                        isFinished = false;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isOnline', _isOnline);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_isOnline) ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatusCard(
                          'New Orders',
                          orders
                              .where((order) => order.status == 'placed')
                              .length
                              .toString(),
                        ),
                        _buildStatusCard(
                          'Accepted',
                          orders
                              .where(
                                  (order) => order.status == 'accepted')
                              .length
                              .toString(),
                        ),
                        _buildStatusCard(
                          'Ready to Deliver',
                          orders
                              .where((order) => order.status == 'ready')
                              .length
                              .toString(),
                        ),
                        _buildStatusCard(
                          'Picked Up',
                          orders
                              .where((order) => order.status == 'picked')
                              .length
                              .toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildSegmentButton(
                          label: 'Preparation',
                          selected: _selectedTabIndex == 0,
                          onTap: () =>
                              setState(() => _selectedTabIndex = 0),
                        ),
                        _buildSegmentButton(
                          label: 'Ready',
                          selected: _selectedTabIndex == 1,
                          onTap: () =>
                              setState(() => _selectedTabIndex = 1),
                        ),
                        _buildSegmentButton(
                          label: 'Picked',
                          selected: _selectedTabIndex == 2,
                          onTap: () =>
                              setState(() => _selectedTabIndex = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    displayedOrders.isEmpty
                        ? _buildNoOrdersUI(noOrdersText)
                        : Column(
                      children: displayedOrders
                          .asMap()
                          .entries
                          .map<Widget>((entry) {
                        final index = entry.key;
                        final order = entry.value;
                        return _buildOrderCard(
                            order, index, displayedOrders);
                      }).toList(),
                    ),
                  ] else ...[
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/offline.png',
                              width: 150,
                              height: 150,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your restaurant is currently offline. Slide the toggle button to go online.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade400,
                width: 0.2,
              ),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFFFFFFFF),
            currentIndex: _selectedBottomIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF1B6FF5),
            unselectedItemColor: Colors.black54,
            onTap: _onBottomNavTap,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/Order.svg',
                  width: 24,
                  height: 24,
                  color: _selectedBottomIndex == 0
                      ? const Color(0xFF1B6FF5)
                      : const Color.fromARGB(136, 0, 0, 0),
                ),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/Menu.svg',
                  width: 24,
                  height: 24,
                  color: _selectedBottomIndex == 1
                      ? const Color(0xFF1B6FF5)
                      : const Color.fromARGB(136, 0, 0, 0),
                ),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/report.svg',
                  width: 24,
                  height: 24,
                  color: _selectedBottomIndex == 2
                      ? const Color(0xFF1B6FF5)
                      : const Color.fromARGB(137, 0, 0, 0),
                ),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/wallet.svg',
                  width: 24,
                  height: 24,
                  color: _selectedBottomIndex == 3
                      ? const Color(0xFF1B6FF5)
                      : const Color.fromARGB(137, 0, 0, 0),
                ),
                label: 'Earnings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoOrdersUI(String noOrdersText) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/food.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 8),
              Text(
                noOrdersText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BAUHAUSM',
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: iconPath.endsWith('.svg')
          ? SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        color: const Color(0xFF1B6FF5),
      )
          : Image.asset(
        iconPath,
        width: 24,
        height: 24,
        color: const Color(0xFF1B6FF5),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: Colors.white,
      hoverColor: Colors.grey.shade100,
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuWidget()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnalysisWidget()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Group2541Widget()),
        );
        break;
    }
  }

  Widget _buildStatusCard(String title, String count) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 22,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(right: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1B6FF5) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBadgeColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.yellow.shade600;
      case 'accepted':
        return Colors.orange.shade600;
      case 'ready':
        return Colors.blue.shade600;
      case 'picked':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  void _onAccept(int index, List<OrderData> orders) async {
    final order = orders[index];
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'status': 'accepted',
        'acceptedTime': Timestamp.now(),
      });
      setState(() {
        order.status = 'accepted';
      });
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  void _onDecline(int index, List<OrderData> orders) async {
    final order = orders[index];
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .delete();
    } catch (e) {
      print('Error deleting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decline order')),
      );
    }
  }

  void _onMarkReady(int index, List<OrderData> orders) async {
    final order = orders[index];
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'status': 'ready',
        'readyTime': Timestamp.now(),
      });
      setState(() {
        order.status = 'ready';
      });
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  void _onMarkPickedUp(int index, List<OrderData> orders) async {
    final order = orders[index];
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({
        'status': 'picked',
        'pickupTime': Timestamp.now(),
      });

      final DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .get();
      final data = orderDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance
          .collection('RestaurantUsers')
          .doc(_restaurantId)
          .collection('orderdetails')
          .doc(order.id)
          .set({
        'userId': data['userId'] ?? '',
        'dishes': data['dishes'] ?? [],
        'subtotal': data['subtotal'] ?? 0,
        'deliveryAddress': data['deliveryAddress'] ?? '',
        'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
        'totalBill': data['totalBill'] ?? 0,
        'GST': data['GST'] ?? 0,
        'acceptedTime': data['acceptedTime'],
        'readyTime': data['readyTime'],
        'pickupTime': data['pickupTime'] ?? FieldValue.serverTimestamp(),
      });

      setState(() {
        order.status = 'picked';
      });
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  Widget _buildOrderCard(OrderData order, int index, List<OrderData> orders) {
    final badgeColor = _getBadgeColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${order.id} - ${order.customerName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.price} • ${order.timeAgo}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.items,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (order.status == 'placed') ...[
            OrderActionWidget(
              initialPrepMinutes: 10, // Default preparation time of 10 minutes
              orderId: order.id,
              onAccept: () => _onAccept(index, orders),
              onDecline: () => _onDecline(index, orders),
              onTimeout: () => _onDecline(index, orders), // Auto-reject on timeout
            ),
          ] else if (order.status == 'accepted') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _onMarkReady(index, orders),
                child: const Text('Mark as Ready'),
              ),
            ),
          ] else if (order.status == 'ready') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => _onMarkPickedUp(index, orders),
                child: const Text('Mark as Picked Up'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void main() {
  runApp(const HomeWidget());
}