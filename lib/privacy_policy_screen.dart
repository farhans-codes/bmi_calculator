import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Effective Date: April 22, 2026\nLast Updated: April 22, 2026',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Introduction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to BMI Calculator ("we," "our," or "us"). We are committed to protecting your privacy. This Privacy Policy explains our practices regarding the collection, use, and disclosure of information when you use our mobile application.\n\n'
              'Our primary goal is to provide a simple, secure, and offline tool to help you calculate your Body Mass Index (BMI) without compromising your privacy.',
            ),
            const SizedBox(height: 20),
            const Text(
              '2. Data Collection and Use',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We strongly believe in data privacy. Therefore, we do NOT collect, store, transmit, or share any personal data.\n\n'
              '• Local Processing: All data you enter into the app (such as age, gender, height, and weight) is processed entirely locally on your device\'s memory.\n'
              '• No Cloud Storage: We do not use any servers or cloud databases to store your health metrics or calculations.\n'
              '• Local Storage (If applicable): If the app saves your recent calculations or preferences, this data is saved securely on your device\'s local storage. It never leaves your phone and is completely deleted if you clear the app\'s data or uninstall the application.',
            ),
            const SizedBox(height: 20),
            const Text(
              '3. App Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our app respects your device\'s security and operates with minimal requirements.\n\n'
              '• No Sensitive Permissions: We do NOT request access to your Camera, Contacts, Location (GPS), Microphone, or Storage files.\n'
              '• Internet Access: The app functions 100% offline and does not require an active internet connection to perform calculations.',
            ),
            const SizedBox(height: 20),
            const Text(
              '4. Third-Party Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To ensure maximum privacy and a seamless experience, this application:\n\n'
              '• Does NOT use any third-party analytics services (like Google Analytics or Firebase).\n'
              '• Does NOT contain any third-party advertising networks (like Google AdMob).\n'
              '• Does NOT track your usage behavior or device identifiers.',
            ),
            const SizedBox(height: 20),
            const Text(
              '5. Data Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Even though we do not collect or transmit your data, we design our application using modern security practices to ensure that the data you input remains isolated within the app\'s local environment on your device.',
            ),
            const SizedBox(height: 20),
            const Text(
              '6. Children\'s Privacy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our application is safe for all ages. Because we do not collect any personal information whatsoever, we do not knowingly collect personally identifiable information from children under the age of 13.',
            ),
            const SizedBox(height: 20),
            const Text(
              '7. Changes to This Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We may update our Privacy Policy from time to time to reflect changes in our app\'s features or legal requirements. Any changes will be updated on this page, and the "Last Updated" date at the top will be modified accordingly. We advise you to review this page periodically for any changes.',
            ),
            const SizedBox(height: 20),
            const Text(
              '8. Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions, suggestions, or concerns regarding this Privacy Policy or our app, please feel free to contact us at:\n\n'
              'Email: sadikfarhan038@gmail.com',
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
