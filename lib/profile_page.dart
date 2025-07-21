import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yammy_restaurent_partner/home_screen.dart';
import 'package:yammy_restaurent_partner/add_menu_item_screen.dart';
import 'package:yammy_restaurent_partner/analytics_screen.dart';
import 'package:yammy_restaurent_partner/operating_hours_page.dart';
import 'package:yammy_restaurent_partner/edit_restaurant_details.dart';
import 'settings_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'restaurant_details.dart';
import 'edit_owner_details.dart';
import 'edit_restaurant_details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProfilePage());
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }
    final uid = user.uid;

    final restaurantSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('RestaurantDetails')
        .doc(uid)
        .get();

    final ownerSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('OwnerDetails')
        .doc(uid)
        .get();

    final orderDetailsSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('orderdetails')
        .get();

    final menuItemsSnapshot = await FirebaseFirestore.instance
        .collection('RestaurantUsers')
        .doc(uid)
        .collection('RestaurantDetails')
        .doc(uid)
        .collection('MenuItems')
        .get();

    final restaurantData = restaurantSnapshot.data() ?? {};
    final ownerData = ownerSnapshot.data() ?? {};
    final orderDocs = orderDetailsSnapshot.docs;
    final menuItemsCount = menuItemsSnapshot.docs.length;

    final currentDate = DateTime.now();
    final startOfDay =
    DateTime(currentDate.year, currentDate.month, currentDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    int dailyOrders = 0;
    double dailyRevenue = 0.0;

    for (var doc in orderDocs) {
      final data = doc.data();
      final Timestamp? pickupTimestamp = data['pickupTime'];
      if (pickupTimestamp != null) {
        final pickupDate = pickupTimestamp.toDate();
        if (pickupDate.isAfter(startOfDay) && pickupDate.isBefore(endOfDay)) {
          dailyOrders++;
          final totalBill = data['totalBill'];
          if (totalBill is num) {
            dailyRevenue += totalBill.toDouble();
          } else if (totalBill is String) {
            dailyRevenue += double.tryParse(totalBill) ?? 0.0;
          }
        }
      }
    }

    return {
      'restaurantName': restaurantData['restaurantName'] ?? 'Restaurant Name',
      'fssaiLicenseNumber':
      restaurantData['fssaiLicenseNumber'] ?? 'FSSAI Number',
      'address': restaurantData['address'] ?? 'Restaurant Address',
      'images': restaurantData['images'] ?? [],
      'phone': ownerData['phone'] ?? 'Phone Number',
      'email': ownerData['email'] ?? 'Email Address',
      'dailyOrders': dailyOrders.toString(),
      'dailyRevenue': '₹${dailyRevenue.toStringAsFixed(2)}',
      'menuItemsCount': menuItemsCount.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      ),
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          titleSpacing: 0,
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
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _fetchProfileData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.discreteCircle(
                  color: const Color(0xFF1B6FF5),
                  size: 50,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final data = snapshot.data!;
            final List<dynamic> images = data['images'] as List<dynamic>;
            final String? firstImageUrl =
            images.isNotEmpty ? images[0] as String? : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Identity Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: firstImageUrl != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  firstImageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return Center(
                                      child: LoadingAnimationWidget
                                          .twoRotatingArc(
                                        color: const Color(0xFF1B6FF5),
                                        size: 40,
                                      ),
                                    );
                                  },
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.error,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              )
                                  : Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['restaurantName'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'FSSAI No: ${data['fssaiLicenseNumber']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Daily Orders',
                          value: data['dailyOrders'],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Revenue',
                          value: data['dailyRevenue'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              'assets/images/location.svg',
                              width: 20,
                              height: 20,
                              color: const Color(0xFF1B6FF5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['address'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Color(0xFF1B6FF5),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RestaurantEditScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/mobile-notch.svg',
                              width: 20,
                              height: 20,
                              color: const Color(0xFF1B6FF5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              data['phone'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/Contact.svg',
                              width: 20,
                              height: 20,
                              color: const Color(0xFF1B6FF5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              data['email'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          iconPath: 'assets/images/Menu.svg',
                          title: 'Menu Management',
                          subtitle: '${data['menuItemsCount']} items',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MenuWidget()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuItem(
                          iconPath: 'assets/images/report.svg',
                          title: 'Analytics',
                          subtitle: 'View reports',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AnalysisWidget()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuItem(
                          iconPath: 'assets/images/time-fast.svg',
                          title: 'Operating Hours',
                          subtitle: 'Set schedule',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const OperatingHoursPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMenuItem(
                          iconPath: 'assets/images/gears.svg',
                          title: 'Settings',
                          subtitle: 'Preferences',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SettingsPage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: const Color(0xFF1B6FF5),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap to view',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}