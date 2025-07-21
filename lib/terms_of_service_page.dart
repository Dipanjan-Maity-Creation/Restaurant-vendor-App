import 'package:flutter/material.dart';
import 'settings_screen.dart';


class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to SettingsPage when back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF), // White background
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
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          title: const Text(
            'Terms of Service',
            style: TextStyle(
              fontFamily: "Poppins",
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large left-aligned "Terms of Service" title with word wrap
                const Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 48, // Increased font size to force "Service" to second line
                    fontWeight: FontWeight.bold, // Bold for emphasis
                    color: Colors.black,
                    height: 1.2, // Adjust line height for better spacing
                  ),
                  softWrap: true, // Allow text to wrap
                ),
                const SizedBox(height: 16), // Spacing between title and subtitle
                // Subtitle with last updated date
                const Text(
                  'Last updated on February 15, 2024',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24), // Increased spacing before sections
                _buildSection(
                  'I. Acceptance of terms',
                  'Thank you for using Yaammy. These Terms of Service (the "Terms") are intended to make you aware of your legal rights and responsibilities with respect to your access to and use of the Yaammy application. These Terms are effective for all existing and future users.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'II. User Eligibility',
                  'By accessing and using the Yaammy application, you confirm that you are at least 16 years of age or above. Users under 16 must have parental consent to use our services. We reserve the right to terminate accounts of users who provide false age information or violate these terms.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'III. Use of the Yaammy App',
                  'The Yaammy application is designed for personal, non-commercial use only. Users agree not to modify, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell any information obtained from the Yaammy application.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'IV. Account Security',
                  'Users are responsible for maintaining the confidentiality of their account credentials and for all activities that occur under their account. Any unauthorized use or security breaches should be reported immediately to our support team.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'V. Privacy Policy',
                  'Your use of the Yaammy application is also governed by our Privacy Policy. By using Yaammy, you consent to the collection, use, and sharing of your information as described in our Privacy Policy.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'VI. Order Processing',
                  'All orders placed through Yaammy are subject to availability and confirmation. We reserve the right to refuse service, cancel orders, or limit quantities at our discretion. Prices and availability are subject to change without notice.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'VII. Payment Terms',
                  'Users agree to pay all fees and charges associated with their orders. We accept various payment methods and process payments securely. All transactions are final unless otherwise specified in our refund policy.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'VIII. Delivery Policy',
                  'Delivery times are estimates and may vary based on location and circumstances. Yaammy is not responsible for delays caused by external factors. Users must provide accurate delivery information.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}


void main() {
  runApp(MaterialApp(
    home: const TermsOfServicePage(),
    theme: ThemeData(
      fontFamily: 'Poppins', // Default font for the app
      primarySwatch: Colors.blue,
    ),
  ));
}