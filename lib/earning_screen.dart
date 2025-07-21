import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Added for SVG support

// Placeholder imports for your other screens/pages.
// Replace with your actual classes.
import 'home_screen.dart';
import 'package:yammy_restaurent_partner/add_menu_item_screen.dart';
import 'analytics_screen.dart';

class Group2541Widget extends StatefulWidget {
  const Group2541Widget({super.key});

  @override
  State<Group2541Widget> createState() => _Group2541WidgetState();
}

class _Group2541WidgetState extends State<Group2541Widget> {
  // Bottom nav index (3 = "Earnings")
  int _selectedBottomIndex = 3;

  // Method to show the payout method selection dialog
  void _showPayoutMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Border radius of 8
          ),
          backgroundColor: const Color(0xFFFFFFFF), // White background
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: "Select Payout Method" and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Payout Method',
                      style: TextStyle(
                        fontFamily: 'BAUHAUSM',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // UPI Option
                _buildPayoutOption(
                  iconPath: 'assets/images/qr.svg', // Updated to use qr.svg
                  title: 'Request UPI Pay',
                  subtitle: 'Instant transfer to your registered UPI ID',
                  onTap: () {
                    debugPrint('UPI Payout Selected');
                    Navigator.of(context).pop();
                    // Add UPI payout logic here
                  },
                ),

                const SizedBox(height: 16),
                // Processing times text
                Text(
                  'Processing times: UPI - Instant | Bank - 1-2 business days',
                  style: TextStyle(
                    fontFamily: 'BAUHAUSM',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build each payout option
  Widget _buildPayoutOption({
    required String iconPath, // Changed to accept icon path for SVG
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD0E4FF), // Updated background color
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                iconPath,
                color: const Color(0xFF1B6FF5), // Updated icon color
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'BAUHAUSM',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'BAUHAUSM',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use Poppins font throughout.
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          titleSpacing: 0, // Closer positioning of the title to the menu icon.
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 40,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // Example back navigation to HomeWidget.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeWidget()),
              );
            },
          ),
          centerTitle: false,
          title: const Text(
            'Earnings',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          // Date selection option removed from actions.
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed row for 2 cards: "Total Payout" and "Pending"
              Row(
                children: [
                  Expanded(
                    child: _buildEarningsCard(
                      title: 'Total Payout',
                      amount: '₹12,458.90',
                      backgroundColor: Colors.green.shade50,
                      extraInfoIcon: Icons.arrow_upward,
                      extraInfoText: '+8.2%',
                      extraInfoColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildEarningsCard(
                      title: 'Pending',
                      amount: '₹2,145.30',
                      backgroundColor: Colors.orange.shade50,
                      extraInfoText: 'Processing',
                      extraInfoColor: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // "Request Payout" button section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.black, // Text and icon interaction color
                        side: const BorderSide(
                            color: Colors.black, width: 1.5), // Black border
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.white, // Clean white background
                      ),
                      onPressed: () {
                        _showPayoutMethodDialog(); // Show the dialog on press
                      },
                      icon: SvgPicture.asset(
                        'assets/images/wallet.svg',
                        width: 20,
                        height: 20,
                        color: const Color.fromARGB(
                            255, 0, 0, 0), // Blue icon color
                      ),
                      label: const Text(
                        'Request Payout',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black, // Black text
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Centered "Minimum Payout" text.
                  const Center(
                    child: Text(
                      'Minimum payout amount: \$50',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // "Payout History" box with additional entries.
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payout History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Payout rows.
                    _buildPayoutCard(
                      amount: '₹3,245.50',
                      date: 'Oct 15, 2023',
                      transactionId: '#TRX-89245',
                      status: 'Completed',
                      statusColor: Colors.green,
                    ),
                    _buildPayoutCard(
                      amount: '₹2,890.75',
                      date: 'Oct 8, 2023',
                      transactionId: '#TRX-89244',
                      status: 'Completed',
                      statusColor: Colors.green,
                    ),
                    _buildPayoutCard(
                      amount: '₹4,120.25',
                      date: 'Oct 1, 2023',
                      transactionId: '#TRX-89243',
                      status: 'Completed',
                      statusColor: Colors.green,
                    ),
                    _buildPayoutCard(
                      amount: '₹1,980.00',
                      date: 'Sep 25, 2023',
                      transactionId: '#TRX-89242',
                      status: 'Completed',
                      statusColor: Colors.green,
                    ),
                    _buildPayoutCard(
                      amount: '₹2,750.00',
                      date: 'Sep 18, 2023',
                      transactionId: '#TRX-89241',
                      status: 'Completed',
                      statusColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom Navigation Bar with white background and grey line.
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // White background
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade400, // Grey line
                width: 0.2, // 0.4 weight
              ),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFFFFFFFF), // Ensure white background
            currentIndex: _selectedBottomIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF1B6FF5),
            unselectedItemColor: Colors.black54,
            onTap: _onBottomNavTap,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/images/Order.svg', // Updated to SVG
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
                  'assets/images/Menu.svg', // Updated to SVG
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
                  'assets/images/report.svg', // Updated to SVG
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
                  'assets/images/wallet.svg', // Updated to SVG
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

  /// Bottom navigation logic.
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnalysisWidget()),
        );
        break;
      case 3:
        // Already on Earnings.
        break;
    }
  }

  /// Earnings card with tinted background.
  Widget _buildEarningsCard({
    required String title,
    required String amount,
    required Color backgroundColor,
    String? extraInfoText,
    Color? extraInfoColor,
    IconData? extraInfoIcon,
  }) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // Use black for rupee amount.
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          // Extra info row if provided.
          if (extraInfoText != null && extraInfoText.isNotEmpty)
            Row(
              children: [
                if (extraInfoIcon != null)
                  Icon(
                    extraInfoIcon,
                    color: extraInfoColor ?? Colors.black,
                    size: 14,
                  ),
                if (extraInfoIcon != null) const SizedBox(width: 2),
                Text(
                  extraInfoText,
                  style: TextStyle(
                    color: extraInfoColor ?? Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// A single payout item row.
  Widget _buildPayoutCard({
    required String amount,
    required String date,
    required String transactionId,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            transactionId,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
