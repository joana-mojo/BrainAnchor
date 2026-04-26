import 'package:flutter/material.dart';

class TermsAndPrivacyDialogs {
  static void showTermsOfUse(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms of Use'),
          content: SingleChildScrollView(
            child: const Text('''

1. Acceptance
By using this Platform, you agree to these Terms. If you do not agree, do not use the app.

2. Purpose
This Platform connects patients with licensed mental health providers for consultations and appointments. It does not replace emergency or hospital care.

3. Accounts
• Provide accurate and updated information
• Keep your account secure
• Providers must submit valid credentials

4. Responsibilities
• Providers: Deliver ethical, lawful, and confidential services
• Patients: Provide truthful information and respect appointments

5. Appointments & Payments
• Subject to provider availability
• Payments and cancellations follow provider policies

6. Prohibited Use
Do not:
• Use the platform for illegal or harmful activities
• Share false information
• Hack, abuse, or harass others

7. Medical Disclaimer
This app is not for emergencies. If you are in danger, contact local emergency services immediately.

8. Liability
The Platform only connects users. We are not responsible for consultation outcomes, user behavior, or technical issues.

9. Termination
Accounts violating these terms may be suspended or removed.

10. Updates
Terms may change anytime. Continued use means acceptance.'''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: const Text('''

1. Compliance
We comply with the Philippine Data Privacy Act of 2012 (RA 10173) and protect your personal data with appropriate safeguards.

2. Data We Collect
• Patients: Name, birthdate, gender, contact details, optional health info
• Providers: Name, license, specialization, contact details

3. How We Use Data
• Manage appointments and services
• Verify provider credentials
• Send notifications
• Improve the platform

4. Data Protection
We use security measures (e.g., encryption, secure servers). However, no system is completely secure.

5. Confidentiality
Patient-provider communications are treated as confidential. Providers must follow professional privacy standards.

6. Data Sharing
We do not sell your data. We only share data:
• With your consent
• When required by law
• For essential app functions

7. Your Rights (RA 10173)
You have the right to:
• Access your data
• Correct inaccurate data
• Request deletion (subject to law)
• Withdraw consent anytime

8. Data Retention
Data is kept only as long as necessary for services and legal compliance.

9. Third-Party Services
We may use third-party services (e.g., payments, analytics) with their own policies.

10. Children’s Privacy
Users under 18 require parental/guardian consent.

11. Updates
We may update this policy. Continued use means acceptance.

12. Contact
For concerns, contact us via the app.'''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
