import 'package:charms/models/user.dart';
import 'package:charms/widgets/report/report_type.dart';
import 'package:flutter/material.dart';
import 'package:charms/utils/responsive_helper.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({
    super.key,
    required this.isstaff,
    // required this.userid,
    required this.user,
    required this.hostname,
  });

  final bool isstaff;
  // final int userid;
  final User user;
  final String hostname;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHARMS Report'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
          child: ReportType(isstaff: isstaff, user: user, hostname: hostname),
        ),
      ),
    );
  }
}
