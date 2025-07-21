import 'package:flutter/material.dart';
import 'settings_screen.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
            'Privacy Policy',
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
                // Large left-aligned "Privacy Policy" title with word wrap
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 48, // Large font size to force "Policy" to second line
                    fontWeight: FontWeight.bold, // Bold for emphasis
                    color: Colors.black,
                    height: 1.2, // Adjust line height for better spacing
                  ),
                  softWrap: true, // Allow text to wrap
                ),
                const SizedBox(height: 16), // Spacing between title and subtitle
                // Subtitle with last updated date
                const Text(
                  'Last updated on April 05, 2025',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24), // Increased spacing before sections
                _buildSection(
                  'I. Information We Collect',
                  'We may collect the following types of information:\n\n'
                  'a. Personal Information\n'
                  '- Account Information: When you register as a restaurant partner, we collect your name, email address, phone number, business name, address, and tax identification number (if applicable).\n'
                  '- Payment Information: Details such as bank account information or payment processor details (e.g., UPI ID) for processing payouts.\n'
                  '- Order and Transaction Data: Information about orders processed through the App, including order details, amounts, and timestamps.\n\n'
                  'b. Usage Data\n'
                  'We collect data on how you interact with the App, such as menu management activities, order processing, and settings updates, through analytics tools.\n\n'
                  'c. Device Information\n'
                  'Information about the device you use to access the App, including IP address, device type, operating system, and unique device identifiers.\n\n'
                  'd. Location Data\n'
                  'With your consent, we may collect approximate location data to optimize delivery logistics and service availability.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'II. How We Use Your Information',
                  'We use your information for the following purposes:\n\n'
                  '- To create and manage your restaurant partner account.\n'
                  '- To process payments and manage payouts to you.\n'
                  '- To provide, maintain, and improve the App’s functionality, including menu management, order tracking, and business hours settings.\n'
                  '- To communicate with you about your account, updates, or support requests.\n'
                  '- To ensure compliance with legal obligations, such as tax reporting or fraud prevention.\n'
                  '- To analyze usage patterns and enhance user experience through aggregated, anonymized data.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'III. How We Share Your Information',
                  'We do not sell your personal information. We may share your data with:\n\n'
                  '- Service Providers: Third-party vendors (e.g., payment processors, cloud storage providers) who assist us in operating the App, under strict confidentiality agreements.\n'
                  '- Legal Authorities: If required by law or to protect the rights, property, or safety of Yaammy, our users, or the public.\n'
                  '- Business Transfers: In the event of a merger, acquisition, or sale of assets, your information may be transferred to the new entity, subject to this Privacy Policy.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'IV. Data Security',
                  'We implement reasonable security measures (e.g., encryption, secure servers) to protect your information from unauthorized access, loss, or alteration. However, no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'V. Your Rights and Choices',
                  'Depending on your location, you may have the following rights regarding your personal data:\n\n'
                  '- Access and Correction: Request access to or correction of your personal information.\n'
                  '- Deletion: Request deletion of your data, subject to legal retention requirements.\n'
                  '- Opt-Out: Opt out of marketing communications by adjusting your account settings or contacting us.\n'
                  'To exercise these rights, email us at privacy@yaammy.com.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'VI. Data Retention',
                  'We retain your personal information only as long as necessary to fulfill the purposes outlined in this policy, unless a longer retention period is required or permitted by law.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'VII. Cookies and Tracking Technologies',
                  'The App may use cookies or similar technologies to enhance functionality and analyze usage. You can manage cookie preferences through your device settings, though this may affect certain features.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'VIII. Children’s Privacy',
                  'The App is not intended for individuals under 18. We do not knowingly collect data from children. If we become aware of such collection, we will delete the information promptly.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'IX. International Data Transfers',
                  'Your information may be transferred to and processed in countries outside your region. We ensure appropriate safeguards are in place, such as standard contractual clauses, to protect your data.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'X. Changes to This Privacy Policy',
                  'We may update this Privacy Policy periodically. The "Last Updated" date at the top reflects the latest version. We will notify you of significant changes via the App or email. Your continued use of the App after changes constitutes acceptance of the updated policy.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'XI. Contact Us',
                  'If you have questions or concerns about this Privacy Policy or your data, please contact us at:\n\n'
                  'Email: privacy@yaammy.com\n'
                  'Address: Yaammy Headquarters, Ratnali, P.O. Radhaballavpur, P.S. Tamluk, Taluka Tamluk, Dist. Purba Medinipur, Pin - 721627',
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
    home: const PrivacyPolicyPage(),
    theme: ThemeData(
      fontFamily: 'Poppins', // Default font for the app
      primarySwatch: Colors.blue,
    ),
  ));
}