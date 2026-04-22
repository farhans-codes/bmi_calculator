import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: April 22, 2026',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            Text(
              'Introduction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'BMI Calculator ("we", "our", or "us") is committed to protecting your privacy. '
              'This Privacy Policy explains how we handle information when you use our mobile application.',
            ),
            SizedBox(height: 16),
            Text(
              'Data Collection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We do NOT collect, store, or transmit any personal data. '
              'All calculations (weight, height, BMI) are performed locally on your device '
              'and are never sent to any server or third party.',
            ),
            SizedBox(height: 16),
            Text(
              'Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This app does not require any special permissions. '
              'It does not access your camera, contacts, location, or any other sensitive data.',
            ),
            SizedBox(height: 16),
            Text(
              'Third-Party Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This app does not use any third-party analytics, advertising, or tracking services.',
            ),
            SizedBox(height: 16),
            Text(
              'Changes to This Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We may update this Privacy Policy from time to time. '
              'Any changes will be reflected in the app with an updated date.',
            ),
            SizedBox(height: 16),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions about this Privacy Policy, '
              'please contact us at flutter.maxcode@gmail.com.',
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
