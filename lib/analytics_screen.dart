import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'earning_screen.dart';
import 'package:yammy_restaurent_partner/add_menu_item_screen.dart';

class AnalysisWidget extends StatefulWidget {
  const AnalysisWidget({super.key});

  @override
  State<AnalysisWidget> createState() => _AnalysisWidgetState();
}

class _AnalysisWidgetState extends State<AnalysisWidget> {
  int _selectedBottomIndex = 2;
  String _selectedFilter = 'Day';
  final List<String> _filters = ['Day', 'Week', 'Month', 'Year'];

  final Map<String, dynamic> _timeData = {
    'Day': {
      'revenue': 0.0,
      'comparison': '0.0% vs last day',
      'orders': '0',
      'customers': '0',
      'growth': '0.0%',
      'categories': {
        'Veg': 0.0,
        'Non-Veg': 0.0,
        'Desserts': 0.0,
        'Drinks': 0.0,
      },
    },
    'Week': {
      'revenue': 0.0,
      'comparison': '0.0% vs last week',
      'orders': '0',
      'customers': '0',
      'growth': '0.0%',
      'categories': {
        'Veg': 0.0,
        'Non-Veg': 0.0,
        'Desserts': 0.0,
        'Drinks': 0.0,
      },
    },
    'Month': {
      'revenue': 0.0,
      'comparison': '0.0% vs last month',
      'orders': '0',
      'customers': '0',
      'growth': '0.0%',
      'categories': {
        'Veg': 0.0,
        'Non-Veg': 0.0,
        'Desserts': 0.0,
        'Drinks': 0.0,
      },
    },
    'Year': {
      'revenue': 0.0,
      'comparison': '0.0% vs last year',
      'orders': '0',
      'customers': '0',
      'growth': '0.0%',
      'categories': {
        'Veg': 0.0,
        'Non-Veg': 0.0,
        'Desserts': 0.0,
        'Drinks': 0.0,
      },
    },
  };

  @override
  void initState() {
    super.initState();
    if (_selectedFilter == 'Day') {
      _fetchTodayData();
    }
  }

  Future<void> _fetchTodayData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _timeData['Day'] = {
          'revenue': 0.0,
          'comparison': '0.0% vs last day',
          'orders': '0',
          'customers': '0',
          'growth': '0.0%',
          'categories': {'Veg': 0.0, 'Non-Veg': 0.0, 'Desserts': 0.0, 'Drinks': 0.0},
        };
      });
      return;
    }
    final uid = user.uid;

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    final endOfYesterday = startOfToday;

    final orderDetailsSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('orderdetails')
        .get();

    double todayRevenue = 0.0;
    int todayOrders = 0;
    final uniqueCustomers = <String>{};
    double yesterdayRevenue = 0.0;
    final categoryCounts = {
      'Veg': 0,
      'Non-Veg': 0,
      'Desserts': 0,
      'Drinks': 0,
    };

    for (var doc in orderDetailsSnapshot.docs) {
      final data = doc.data();
      final Timestamp? pickupTimestamp = data['pickupTime'];
      if (pickupTimestamp != null) {
        final pickupDate = pickupTimestamp.toDate();
        if (pickupDate.isAfter(startOfToday) && pickupDate.isBefore(endOfToday)) {
          todayOrders++;
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            todayRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            todayRevenue += double.tryParse(totalBill) ?? 0.0;
          }
          final userId = data['userId'] as String? ?? '';
          uniqueCustomers.add(userId);

          // Count individual items by category
          final dishes = data['dishes'] as List<dynamic>? ?? [];
          for (var dish in dishes) {
            final category = dish['category'] as String?;
            if (category == 'Veg Items') categoryCounts['Veg'] = categoryCounts['Veg']! + 1;
            if (category == 'Non-Veg') categoryCounts['Non-Veg'] = categoryCounts['Non-Veg']! + 1;
            if (category == 'Desserts') categoryCounts['Desserts'] = categoryCounts['Desserts']! + 1;
            if (category == 'Drinks') categoryCounts['Drinks'] = categoryCounts['Drinks']! + 1;
          }
        } else if (pickupDate.isAfter(startOfYesterday) && pickupDate.isBefore(endOfYesterday)) {
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            yesterdayRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            yesterdayRevenue += double.tryParse(totalBill) ?? 0.0;
          }
        }
      }
    }

    String comparison;
    String growth;
    if (yesterdayRevenue == 0) {
      comparison = todayRevenue > 0 ? '+100% vs last day' : '0.0% vs last day';
      growth = todayRevenue > 0 ? '+100%' : '0.0%';
    } else {
      final percentageChange = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
      comparison = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}% vs last day';
      growth = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%';
    }

    setState(() {
      _timeData['Day'] = {
        'revenue': todayRevenue,
        'comparison': comparison,
        'orders': todayOrders.toString(),
        'customers': uniqueCustomers.length.toString(),
        'growth': growth,
        'categories': {
          'Veg': categoryCounts['Veg']!.toDouble(),
          'Non-Veg': categoryCounts['Non-Veg']!.toDouble(),
          'Desserts': categoryCounts['Desserts']!.toDouble(),
          'Drinks': categoryCounts['Drinks']!.toDouble(),
        },
      };
    });
  }

  Future<void> _fetchWeekData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _timeData['Week'] = {
          'revenue': 0.0,
          'comparison': '0.0% vs last week',
          'orders': '0',
          'customers': '0',
          'growth': '0.0%',
          'categories': {'Veg': 0.0, 'Non-Veg': 0.0, 'Desserts': 0.0, 'Drinks': 0.0},
        };
      });
      return;
    }
    final uid = user.uid;

    final today = DateTime.now();
    final startOfCurrentWeek = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    final endOfCurrentWeek = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
    final startOfPreviousWeek = startOfCurrentWeek.subtract(const Duration(days: 7));
    final endOfPreviousWeek = startOfCurrentWeek;

    final orderDetailsSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('orderdetails')
        .get();

    double currentWeekRevenue = 0.0;
    int currentWeekOrders = 0;
    final uniqueCustomers = <String>{};
    double previousWeekRevenue = 0.0;
    final categoryCounts = {
      'Veg': 0,
      'Non-Veg': 0,
      'Desserts': 0,
      'Drinks': 0,
    };

    for (var doc in orderDetailsSnapshot.docs) {
      final data = doc.data();
      final Timestamp? pickupTimestamp = data['pickupTime'];
      if (pickupTimestamp != null) {
        final pickupDate = pickupTimestamp.toDate();
        if (pickupDate.isAfter(startOfCurrentWeek) && pickupDate.isBefore(endOfCurrentWeek)) {
          currentWeekOrders++;
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            currentWeekRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            currentWeekRevenue += double.tryParse(totalBill) ?? 0.0;
          }
          final userId = data['userId'] as String? ?? '';
          uniqueCustomers.add(userId);

          // Count individual items by category
          final dishes = data['dishes'] as List<dynamic>? ?? [];
          for (var dish in dishes) {
            final category = dish['category'] as String?;
            if (category == 'Veg Items') categoryCounts['Veg'] = categoryCounts['Veg']! + 1;
            if (category == 'Non-Veg') categoryCounts['Non-Veg'] = categoryCounts['Non-Veg']! + 1;
            if (category == 'Desserts') categoryCounts['Desserts'] = categoryCounts['Desserts']! + 1;
            if (category == 'Drinks') categoryCounts['Drinks'] = categoryCounts['Drinks']! + 1;
          }
        } else if (pickupDate.isAfter(startOfPreviousWeek) && pickupDate.isBefore(endOfPreviousWeek)) {
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            previousWeekRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            previousWeekRevenue += double.tryParse(totalBill) ?? 0.0;
          }
        }
      }
    }

    String comparison;
    String growth;
    if (previousWeekRevenue == 0) {
      comparison = currentWeekRevenue > 0 ? '+100% vs last week' : '0.0% vs last week';
      growth = currentWeekRevenue > 0 ? '+100%' : '0.0%';
    } else {
      final percentageChange = ((currentWeekRevenue - previousWeekRevenue) / previousWeekRevenue) * 100;
      comparison = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}% vs last week';
      growth = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%';
    }

    setState(() {
      _timeData['Week'] = {
        'revenue': currentWeekRevenue,
        'comparison': comparison,
        'orders': currentWeekOrders.toString(),
        'customers': uniqueCustomers.length.toString(),
        'growth': growth,
        'categories': {
          'Veg': categoryCounts['Veg']!.toDouble(),
          'Non-Veg': categoryCounts['Non-Veg']!.toDouble(),
          'Desserts': categoryCounts['Desserts']!.toDouble(),
          'Drinks': categoryCounts['Drinks']!.toDouble(),
        },
      };
    });
  }

  Future<void> _fetchMonthData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _timeData['Month'] = {
          'revenue': 0.0,
          'comparison': '0.0% vs last month',
          'orders': '0',
          'customers': '0',
          'growth': '0.0%',
          'categories': {'Veg': 0.0, 'Non-Veg': 0.0, 'Desserts': 0.0, 'Drinks': 0.0},
        };
      });
      return;
    }
    final uid = user.uid;

    final today = DateTime.now();
    final startOfCurrentMonth = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 29));
    final endOfCurrentMonth = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
    final startOfPreviousMonth = startOfCurrentMonth.subtract(const Duration(days: 30));
    final endOfPreviousMonth = startOfCurrentMonth;

    final orderDetailsSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('orderdetails')
        .get();

    double currentMonthRevenue = 0.0;
    int currentMonthOrders = 0;
    final uniqueCustomers = <String>{};
    double previousMonthRevenue = 0.0;
    final categoryCounts = {
      'Veg': 0,
      'Non-Veg': 0,
      'Desserts': 0,
      'Drinks': 0,
    };

    for (var doc in orderDetailsSnapshot.docs) {
      final data = doc.data();
      final Timestamp? pickupTimestamp = data['pickupTime'];
      if (pickupTimestamp != null) {
        final pickupDate = pickupTimestamp.toDate();
        if (pickupDate.isAfter(startOfCurrentMonth) && pickupDate.isBefore(endOfCurrentMonth)) {
          currentMonthOrders++;
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            currentMonthRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            currentMonthRevenue += double.tryParse(totalBill) ?? 0.0;
          }
          final userId = data['userId'] as String? ?? '';
          uniqueCustomers.add(userId);

          // Count individual items by category
          final dishes = data['dishes'] as List<dynamic>? ?? [];
          for (var dish in dishes) {
            final category = dish['category'] as String?;
            if (category == 'Veg Items') categoryCounts['Veg'] = categoryCounts['Veg']! + 1;
            if (category == 'Non-Veg') categoryCounts['Non-Veg'] = categoryCounts['Non-Veg']! + 1;
            if (category == 'Desserts') categoryCounts['Desserts'] = categoryCounts['Desserts']! + 1;
            if (category == 'Drinks') categoryCounts['Drinks'] = categoryCounts['Drinks']! + 1;
          }
        } else if (pickupDate.isAfter(startOfPreviousMonth) && pickupDate.isBefore(endOfPreviousMonth)) {
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            previousMonthRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            previousMonthRevenue += double.tryParse(totalBill) ?? 0.0;
          }
        }
      }
    }

    String comparison;
    String growth;
    if (previousMonthRevenue == 0) {
      comparison = currentMonthRevenue > 0 ? '+100% vs last month' : '0.0% vs last month';
      growth = currentMonthRevenue > 0 ? '+100%' : '0.0%';
    } else {
      final percentageChange = ((currentMonthRevenue - previousMonthRevenue) / previousMonthRevenue) * 100;
      comparison = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}% vs last month';
      growth = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%';
    }

    setState(() {
      _timeData['Month'] = {
        'revenue': currentMonthRevenue,
        'comparison': comparison,
        'orders': currentMonthOrders.toString(),
        'customers': uniqueCustomers.length.toString(),
        'growth': growth,
        'categories': {
          'Veg': categoryCounts['Veg']!.toDouble(),
          'Non-Veg': categoryCounts['Non-Veg']!.toDouble(),
          'Desserts': categoryCounts['Desserts']!.toDouble(),
          'Drinks': categoryCounts['Drinks']!.toDouble(),
        },
      };
    });
  }

  Future<void> _fetchYearData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _timeData['Year'] = {
          'revenue': 0.0,
          'comparison': '0.0% vs last year',
          'orders': '0',
          'customers': '0',
          'growth': '0.0%',
          'categories': {'Veg': 0.0, 'Non-Veg': 0.0, 'Desserts': 0.0, 'Drinks': 0.0},
        };
      });
      return;
    }
    final uid = user.uid;

    final today = DateTime.now();
    final startOfCurrentYear = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 364));
    final endOfCurrentYear = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
    final startOfPreviousYear = startOfCurrentYear.subtract(const Duration(days: 365));
    final endOfPreviousYear = startOfCurrentYear;

    final orderDetailsSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('orderdetails')
        .get();

    double currentYearRevenue = 0.0;
    int currentYearOrders = 0;
    final uniqueCustomers = <String>{};
    double previousYearRevenue = 0.0;
    final categoryCounts = {
      'Veg': 0,
      'Non-Veg': 0,
      'Desserts': 0,
      'Drinks': 0,
    };

    for (var doc in orderDetailsSnapshot.docs) {
      final data = doc.data();
      final Timestamp? pickupTimestamp = data['pickupTime'];
      if (pickupTimestamp != null) {
        final pickupDate = pickupTimestamp.toDate();
        if (pickupDate.isAfter(startOfCurrentYear) && pickupDate.isBefore(endOfCurrentYear)) {
          currentYearOrders++;
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            currentYearRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            currentYearRevenue += double.tryParse(totalBill) ?? 0.0;
          }
          final userId = data['userId'] as String? ?? '';
          uniqueCustomers.add(userId);

          // Count individual items by category
          final dishes = data['dishes'] as List<dynamic>? ?? [];
          for (var dish in dishes) {
            final category = dish['category'] as String?;
            if (category == 'Veg Items') categoryCounts['Veg'] = categoryCounts['Veg']! + 1;
            if (category == 'Non-Veg') categoryCounts['Non-Veg'] = categoryCounts['Non-Veg']! + 1;
            if (category == 'Desserts') categoryCounts['Desserts'] = categoryCounts['Desserts']! + 1;
            if (category == 'Drinks') categoryCounts['Drinks'] = categoryCounts['Drinks']! + 1;
          }
        } else if (pickupDate.isAfter(startOfPreviousYear) && pickupDate.isBefore(endOfPreviousYear)) {
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            previousYearRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            previousYearRevenue += double.tryParse(totalBill) ?? 0.0;
          }
        }
      }
    }

    String comparison;
    String growth;
    if (previousYearRevenue == 0) {
      comparison = currentYearRevenue > 0 ? '+100% vs last year' : '0.0% vs last year';
      growth = currentYearRevenue > 0 ? '+100%' : '0.0%';
    } else {
      final percentageChange = ((currentYearRevenue - previousYearRevenue) / previousYearRevenue) * 100;
      comparison = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}% vs last year';
      growth = '${percentageChange >= 0 ? '+' : ''}${percentageChange.toStringAsFixed(1)}%';
    }

    setState(() {
      _timeData['Year'] = {
        'revenue': currentYearRevenue,
        'comparison': comparison,
        'orders': currentYearOrders.toString(),
        'customers': uniqueCustomers.length.toString(),
        'growth': growth,
        'categories': {
          'Veg': categoryCounts['Veg']!.toDouble(),
          'Non-Veg': categoryCounts['Non-Veg']!.toDouble(),
          'Desserts': categoryCounts['Desserts']!.toDouble(),
          'Drinks': categoryCounts['Drinks']!.toDouble(),
        },
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _timeData[_selectedFilter] as Map<String, dynamic>;
    final revenue = data['revenue'] as double;
    final comparison = data['comparison'] as String;
    final ordersVal = data['orders'] as String;
    final customersVal = data['customers'] as String;
    final growthVal = data['growth'] as String;
    final categories = data['categories'] as Map<String, double>;

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
          title: const Text(
            'Analysis',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final bool isSelected = (_selectedFilter == filter);
                    final displayText = filter == 'Day' ? 'Today' : filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: isSelected
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = filter;
                                  if (filter == 'Day') {
                                    _fetchTodayData();
                                  } else if (filter == 'Week') {
                                    _fetchWeekData();
                                  } else if (filter == 'Month') {
                                    _fetchMonthData();
                                  } else if (filter == 'Year') {
                                    _fetchYearData();
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B6FF5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = filter;
                                  if (filter == 'Day') {
                                    _fetchTodayData();
                                  } else if (filter == 'Week') {
                                    _fetchWeekData();
                                  } else if (filter == 'Month') {
                                    _fetchMonthData();
                                  } else if (filter == 'Year') {
                                    _fetchYearData();
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF1B6FF5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  color: Color(0xFF1B6FF5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${revenue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comparison,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          icon: Icons.shopping_bag,
                          label: 'Orders',
                          value: ordersVal,
                        ),
                        _buildStatItem(
                          icon: Icons.person,
                          label: 'Customers',
                          value: customersVal,
                        ),
                        _buildStatItem(
                          icon: Icons.show_chart,
                          label: 'Growth',
                          value: growthVal,
                          valueColor: Colors.black,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Category Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 250,
                  child: _buildBarChart(categories),
                ),
              ),
            ],
          ),
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
                      : Colors.black54,
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
                      : Colors.black54,
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
                      : Colors.black54,
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
                      : Colors.black54,
                ),
                label: 'Earnings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeWidget()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuWidget()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Group2541Widget()),
        );
        break;
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.black, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, double> categories) {
    final catList = categories.entries.toList();
    final maxVal = catList.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Dynamic scaling for maxY
    double maxY;
    if (maxVal <= 2) {
      maxY = 10;
    } else if (maxVal <= 10) {
      maxY = 20;
    } else if (maxVal <= 20) {
      maxY = 30;
    } else {
      maxY = ((maxVal / 10).ceil() * 10).toDouble(); // Round up to next multiple of 10
    }

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final catName = catList[group.x].key;
              final catVal = catList[group.x].value.toInt();
              return BarTooltipItem(
                '$catName\n',
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '• $catVal',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int i = val.toInt();
                if (i < 0 || i >= catList.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    catList[i].key,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5, // Adjust interval dynamically based on maxY
              getTitlesWidget: (val, meta) {
                if (val % (maxY / 5) == 0) {
                  return Text(
                    val.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                } else {
                  return const SizedBox();
                }
              },
              reservedSize: 28,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(catList.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: catList[i].value,
                color: const Color(0xFF1B6FF5),
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}