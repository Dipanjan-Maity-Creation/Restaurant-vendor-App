import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg for SVG support
import 'home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InstructionsScreen(),
      theme: ThemeData(
        fontFamily: 'Quicksand', // Set default font to Poppins globally
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w500), // For AppBar title
        ),
      ),
    );
  }
}

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Background color set to #ffffff
      appBar: AppBar(
        title: const Text(
          'Instructions',
          style: TextStyle(
            fontFamily: 'Poppins', // Explicitly set for AppBar
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 8), // Add some space below AppBar
            Center(
              child: Text(
                'Please read the instructions carefully before proceeding.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Quicksand', // Explicitly set for this text
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              iconWidget: SvgPicture.asset(
                'assets/images/hamburger-soda.svg', // Use SVG for Menu Management
                width: 24,
                height: 24,
                color: const Color(0xFF1B6FF5),
              ),
              title: 'Menu Management',
              description:
                  'To add items, go to the Menu option in the bottom navigation. From there, you can pick categories, name your items, set prices, choose preparation times, and write descriptions.',
            ),
            _buildSection(
               iconWidget: SvgPicture.asset(
                'assets/images/calendar-clock.svg', // Use SVG for Menu Management
                width: 24,
                height: 24,
                color: const Color(0xFF1B6FF5),
              ),
              title: 'Operation Hours',
              description:
                  'Go to the Profile section to set your business hours. After you set them, the times will automatically work for the next day. You can change them anytime if you need to.',
            ),
            _buildSection(
              iconWidget: SvgPicture.asset(
                'assets/images/Balance.svg', // Use SVG for Menu Management
                width: 24,
                height: 24,
                color: const Color(0xFF1B6FF5),
              ),
              title: 'Payout Settings',
              description:
                  'To set up how you get paid, go to Profile > Settings. Add your bank details or UPI information there. This keeps your payments safe and secure.',
            ),
            _buildSection(
              iconWidget: SvgPicture.asset(
                'assets/images/ticket.svg', // Use SVG for Menu Management
                width: 24,
                height: 24,
                color: const Color(0xFF1B6FF5),
              ),
              title: 'Discount Management',
              description:
                  'Create and manage discounts through the side navigation menu. Set discount percentages, validity periods, and applicable items.',
            ),
            _buildSection(
               iconWidget: SvgPicture.asset(
                'assets/images/credit-card.svg', // Use SVG for Menu Management
                width: 24,
                height: 24,
                color: const Color(0xFF1B6FF5),
              ),
              title: 'Earnings & Payouts',
              description:
                  'Track your earnings and request payouts through the Earnings section in the bottom navigation bar.',
            ),
            _buildSection(
              iconWidget: SvgPicture.asset(
                'assets/images/headset.svg', // Use SVG for Menu Management
                width: 24,
                height: 24,
                color: const Color(0xFF1B6FF5),
              ),
              title: 'Support',
              description:
                  'If you need help, our support team is here Monday to Friday from 9 AM to 8 PM and Saturday from 10 AM to 6 PM. You can reach us through the Support section in Profile.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ElevatedButton(
          onPressed: () {
            // Navigate to HomeWidget when Proceed is clicked
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeWidget()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B6FF5), // Blue color for the button
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Proceed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Poppins', // Explicitly set for button text
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    Widget? iconWidget, // Changed to Widget to support SVG
    IconData? icon,    // Keep IconData for other sections
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light grey background
          borderRadius: BorderRadius.circular(8),
          // No border
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Use iconWidget if provided, otherwise use Icon
                iconWidget ?? Icon(icon, color: const Color(0xFF1B6FF5), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500, // Changed to w500 for card titles
                    color: Colors.black,
                    fontFamily: 'Quicksand', // Explicitly set for title
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Quicksand', // Explicitly set for description
              ),
            ),
          ],
        ),
      ),
    );
  }
}
