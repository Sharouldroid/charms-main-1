import 'package:flutter/material.dart';
import 'package:charms/utils/responsive_helper.dart';

class TermsOfServiceScreen extends StatelessWidget {
  static const String routeName = '/terms-of-service';

  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CHARMS',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terms of Service',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Last Updated: December 22, 2025',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Content
              _buildSection(
                context,
                '1. Agreement to Terms',
                'By accessing or using the CHARMS (Chagar Hutang Resource Management System) mobile application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
              ),

              _buildSection(
                context,
                '2. Description of Service',
                'CHARMS is a comprehensive resource management platform for Chagar Hutang that provides:',
                bulletPoints: [
                  'Event Booking & Management: Day trips, volunteer programs (KPP), researcher visits, and special events',
                  'Facility Maintenance Tracking: Kitchen, campsite, outdoor classroom, quarters, water sport areas, office, surau, and other facility maintenance',
                  'Safety Management: Incident reporting, first aid tracking, medical supply management, and water quality monitoring',
                  'Booking Management: Calendar scheduling, boat assignments, and optional item reservations',
                  'Payment Processing: Secure payment transactions via integrated payment services',
                  'User Management: Profile management, certificates, and indemnity forms',
                  'Administrative Functions: Reports, feedback management, and booking settings',
                ],
              ),

              _buildSection(
                context,
                '3. User Accounts',
                null,
                subsections: [
                  _SubSection(
                    '3.1 Registration',
                    'To access certain features of the App, you must create an account. You agree to:',
                    bulletPoints: [
                      'Provide accurate, current, and complete information during registration',
                      'Maintain and promptly update your account information',
                      'Keep your login credentials secure and confidential',
                      'Notify us immediately of any unauthorized access to your account',
                    ],
                  ),
                  _SubSection(
                    '3.2 Account Types',
                    'The App supports different user types with varying levels of access:',
                    bulletPoints: [
                      'General Users/Visitors',
                      'Staff Members',
                      'Administrators',
                    ],
                  ),
                  _SubSection(
                    '3.3 Account Responsibility',
                    'You are responsible for all activities that occur under your account. We reserve the right to suspend or terminate accounts that violate these Terms.',
                  ),
                ],
              ),

              _buildSection(
                context,
                '4. User Conduct',
                'You agree NOT to:',
                bulletPoints: [
                  'Use the App for any unlawful purpose or in violation of any applicable laws',
                  'Impersonate any person or entity or falsely represent your affiliation',
                  'Interfere with or disrupt the App\'s servers or networks',
                  'Attempt to gain unauthorized access to any portion of the App',
                  'Upload viruses, malware, or other malicious code',
                  'Collect or harvest any personally identifiable information from other users',
                  'Use automated systems or software to extract data from the App',
                  'Submit false or misleading information in bookings, reports, or forms',
                  'Misuse safety or incident reporting features',
                ],
              ),

              _buildSection(
                context,
                '5. Bookings and Payments',
                null,
                subsections: [
                  _SubSection(
                    '5.1 Booking Terms',
                    null,
                    bulletPoints: [
                      'All bookings are subject to availability and confirmation',
                      'You must provide accurate participant information for all bookings',
                      'Group bookings require complete information for all group members',
                      'Booking modifications may be subject to availability and additional fees',
                    ],
                  ),
                  _SubSection(
                    '5.2 Payment Terms',
                    null,
                    bulletPoints: [
                      'Payments are processed securely through our integrated payment provider (Stripe)',
                      'All prices are displayed in the applicable currency',
                      'You agree to pay all fees and charges associated with your bookings',
                      'Payment information is encrypted and handled according to PCI-DSS standards',
                    ],
                  ),
                  _SubSection(
                    '5.3 Cancellation and Refunds',
                    null,
                    bulletPoints: [
                      'Cancellation policies vary by event type and will be communicated at the time of booking',
                      'Refund eligibility is determined based on the cancellation timing and event policies',
                      'Administrative fees may apply to cancellations and refunds',
                    ],
                  ),
                ],
              ),

              _buildSection(
                context,
                '6. Indemnity and Liability Waivers',
                null,
                subsections: [
                  _SubSection(
                    '6.1 Indemnity Forms',
                    null,
                    bulletPoints: [
                      'Certain activities may require completion of indemnity forms',
                      'By submitting an indemnity form, you acknowledge the inherent risks associated with outdoor and recreational activities',
                      'Parents or legal guardians must complete indemnity forms for minors',
                    ],
                  ),
                  _SubSection(
                    '6.2 Assumption of Risk',
                    'You acknowledge that participation in camp activities, water sports, backpacking, and other outdoor activities involves inherent risks including but not limited to physical injury, property damage, and natural hazards.',
                  ),
                ],
              ),

              _buildSection(
                context,
                '7. Safety and Compliance',
                null,
                subsections: [
                  _SubSection(
                    '7.1 Safety Guidelines',
                    null,
                    bulletPoints: [
                      'Users must comply with all safety instructions and guidelines provided by staff',
                      'Incident reporting features must be used honestly and accurately',
                      'Emergency contact information must be kept current',
                    ],
                  ),
                  _SubSection(
                    '7.2 Facility Use',
                    null,
                    bulletPoints: [
                      'Users must respect facility rules and maintenance schedules',
                      'Any damage to facilities or equipment must be reported immediately',
                      'Users may be held liable for damage caused by negligence or misconduct',
                    ],
                  ),
                ],
              ),

              _buildSection(
                context,
                '8. Privacy and Data Protection',
                null,
                subsections: [
                  _SubSection(
                    '8.1 Data Collection',
                    'We collect and process personal data as described in our Privacy Policy, including:',
                    bulletPoints: [
                      'Account information (name, email, contact details)',
                      'Booking and transaction history',
                      'Health information (for emergency purposes and medical supply tracking)',
                      'Location data (when necessary for services)',
                    ],
                  ),
                  _SubSection(
                    '8.2 Data Security',
                    null,
                    bulletPoints: [
                      'We implement industry-standard security measures to protect your data',
                      'Sensitive information is stored using secure encryption',
                      'We use secure storage services for authentication credentials',
                    ],
                  ),
                  _SubSection(
                    '8.3 Data Sharing',
                    'We may share your information with:',
                    bulletPoints: [
                      'Camp staff and administrators for service delivery',
                      'Payment processors for transaction handling',
                      'Emergency services when required for safety',
                    ],
                  ),
                ],
              ),

              _buildSection(
                context,
                '9. Intellectual Property',
                null,
                subsections: [
                  _SubSection(
                    '9.1 Ownership',
                    'All content, features, and functionality of the App, including but not limited to text, graphics, logos, icons, images, and software, are the exclusive property of CHARMS and are protected by copyright, trademark, and other intellectual property laws.',
                  ),
                  _SubSection(
                    '9.2 Limited License',
                    'We grant you a limited, non-exclusive, non-transferable license to access and use the App for personal, non-commercial purposes in accordance with these Terms.',
                  ),
                ],
              ),

              _buildSection(
                context,
                '10. Third-Party Services',
                'The App integrates with third-party services including:',
                bulletPoints: [
                  'Stripe: For payment processing',
                  'Google Sign-In: For authentication (if enabled)',
                ],
                additionalText:
                    'Your use of third-party services is subject to their respective terms of service and privacy policies.',
              ),

              _buildSection(
                context,
                '11. Disclaimers',
                null,
                subsections: [
                  _SubSection(
                    '11.1 Service Availability',
                    'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. We do not guarantee that the App will be uninterrupted, error-free, or free of viruses or other harmful components.',
                    isImportant: true,
                  ),
                  _SubSection(
                    '11.2 Limitation of Liability',
                    'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, DATA, OR OTHER INTANGIBLE LOSSES.',
                    isImportant: true,
                  ),
                  _SubSection(
                    '11.3 Activity Risks',
                    'We are not liable for injuries, accidents, or damages that occur during participation in camp activities. All participants engage in activities at their own risk.',
                  ),
                ],
              ),

              _buildSection(
                context,
                '12. Indemnification',
                'You agree to indemnify, defend, and hold harmless CHARMS, its officers, directors, employees, agents, and affiliates from and against any claims, damages, losses, liabilities, costs, and expenses arising from:',
                bulletPoints: [
                  'Your use of the App',
                  'Your violation of these Terms',
                  'Your violation of any third-party rights',
                  'Your participation in camp activities',
                ],
              ),

              _buildSection(
                context,
                '13. Modifications to Terms',
                'We reserve the right to modify these Terms at any time. Changes will be effective immediately upon posting to the App. Your continued use of the App after changes constitutes acceptance of the modified Terms.',
              ),

              _buildSection(
                context,
                '14. Termination',
                null,
                subsections: [
                  _SubSection(
                    '14.1 By You',
                    'You may terminate your account at any time by contacting us or using the account deletion feature if available.',
                  ),
                  _SubSection(
                    '14.2 By Us',
                    'We may suspend or terminate your access to the App at any time, with or without cause, and with or without notice.',
                  ),
                  _SubSection(
                    '14.3 Effect of Termination',
                    'Upon termination:',
                    bulletPoints: [
                      'Your right to use the App ceases immediately',
                      'Outstanding payments remain due',
                      'Provisions that by their nature should survive termination shall survive',
                    ],
                  ),
                ],
              ),

              _buildSection(
                context,
                '15. Governing Law and Dispute Resolution',
                null,
                subsections: [
                  _SubSection(
                    '15.1 Governing Law',
                    'These Terms shall be governed by and construed in accordance with the laws of Malaysia, without regard to its conflict of law provisions.',
                  ),
                  _SubSection(
                    '15.2 Dispute Resolution',
                    'Any disputes arising from these Terms or your use of the App shall be resolved through:',
                    bulletPoints: [
                      'Good faith negotiation',
                      'Mediation',
                      'Binding arbitration or court proceedings in the appropriate jurisdiction',
                    ],
                  ),
                ],
              ),

              _buildSection(
                context,
                '16. Contact Information',
                'If you have any questions about these Terms of Service, please contact us at:',
                contactInfo: true,
              ),

              _buildSection(
                context,
                '17. Miscellaneous',
                null,
                subsections: [
                  _SubSection(
                    '17.1 Entire Agreement',
                    'These Terms constitute the entire agreement between you and CHARMS regarding your use of the App.',
                  ),
                  _SubSection(
                    '17.2 Severability',
                    'If any provision of these Terms is found to be unenforceable, the remaining provisions shall continue in full force and effect.',
                  ),
                  _SubSection(
                    '17.3 Waiver',
                    'Our failure to enforce any right or provision of these Terms shall not constitute a waiver of such right or provision.',
                  ),
                  _SubSection(
                    '17.4 Assignment',
                    'You may not assign or transfer these Terms without our prior written consent. We may assign our rights and obligations under these Terms without restriction.',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'By using CHARMS, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2025 CHARMS. All rights reserved.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String? content, {
    List<String>? bulletPoints,
    List<_SubSection>? subsections,
    String? additionalText,
    bool contactInfo = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Content
          if (content != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                content,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),

          // Bullet Points
          if (bulletPoints != null) ...[
            const SizedBox(height: 8),
            ...bulletPoints.map((point) => _buildBulletPoint(context, point)),
          ],

          // Additional Text
          if (additionalText != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                additionalText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Contact Info
          if (contactInfo) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHARMS Support',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'info@conservems.my',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.language_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'https://conservems.my',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Subsections
          if (subsections != null) ...[
            ...subsections.map((sub) => _buildSubSection(context, sub)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection(BuildContext context, _SubSection subsection) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color:
                subsection.isImportant
                    ? Colors.orange.shade300
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subsection.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  subsection.isImportant
                      ? Colors.orange.shade800
                      : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (subsection.content != null) ...[
            const SizedBox(height: 8),
            Text(
              subsection.content!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontWeight:
                    subsection.isImportant
                        ? FontWeight.w500
                        : FontWeight.normal,
              ),
            ),
          ],
          if (subsection.bulletPoints != null) ...[
            const SizedBox(height: 8),
            ...subsection.bulletPoints!.map(
              (point) => _buildBulletPoint(context, point),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubSection {
  final String title;
  final String? content;
  final List<String>? bulletPoints;
  final bool isImportant;

  _SubSection(
    this.title,
    this.content, {
    this.bulletPoints,
    this.isImportant = false,
  });
}
