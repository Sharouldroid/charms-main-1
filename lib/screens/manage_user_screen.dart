import 'package:charms/models/user.dart';
import 'package:charms/widgets/user/user_list.dart';
import 'package:flutter/material.dart';
import 'package:charms/utils/responsive_helper.dart';

class ManageUserScreen extends StatelessWidget {
  const ManageUserScreen({
    super.key,
    required this.hostname,
    required this.user,
  });

  final String hostname;
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxContentWidth(context)),
          child: UserList(
            hostname: hostname,
            user: user,
          ),
        ),
      ),
    );
  }
}
