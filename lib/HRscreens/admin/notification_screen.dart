import 'package:charms/HRproviders/claims.dart';
import 'package:charms/HRproviders/leaves.dart';
import 'package:charms/HRproviders/payments.dart';
import 'package:charms/HRproviders/payment_claims.dart';
import 'package:charms/HRproviders/schedules.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRmodels/payment_claim.dart';
import 'package:charms/HRscreens/admin/manage_claim_screen.dart';
import 'package:charms/HRscreens/admin/manage_leave_screen.dart';
import 'package:charms/HRscreens/admin/manage_payroll_screen.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:charms/HRmodels/schedule_exchange.dart';
import 'package:charms/HRmodels/schedule.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin =
      kIsWeb ? null : FlutterLocalNotificationsPlugin();

  final Color bgColor     = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) initializeNotifications();
    loadNotifications();
  }

  Future<void> initializeNotifications() async {
    if (kIsWeb || flutterLocalNotificationsPlugin == null) return;
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin!.initialize(initializationSettings);
  }

  Future<void> loadNotifications() async {
    final leavesProvider        = Provider.of<Leaves>(context, listen: false);
    final paymentsProvider      = Provider.of<Payments>(context, listen: false);
    final claimsProvider        = Provider.of<Claims>(context, listen: false);
    final exchangesProvider     = Provider.of<ScheduleExchanges>(context, listen: false);
    final schedulesProvider     = Provider.of<Schedules>(context, listen: false);
    final staffsProvider        = Provider.of<Staffs>(context, listen: false);
    final paymentClaimsProvider = Provider.of<PaymentClaims>(context, listen: false);

    await Future.wait([
      leavesProvider.fetchLeaves(),
      paymentsProvider.fetchPayments(),
      claimsProvider.fetchClaims(),
      exchangesProvider.fetchPendingForHR(),
      schedulesProvider.fetchSchedules(),
      staffsProvider.fetchStaff(),
      paymentClaimsProvider.fetchAllClaims(status: 'Pending'),
    ]);

    if (!kIsWeb) {
      showSystemNotifications(
        leavesProvider.leaves.where((l) => l.status == 'Pending').length,
        paymentsProvider.payments.where((p) => p.status == 'Pending').length,
        claimsProvider.claims.where((c) => c.status == 'Pending').length,
      );
    }
  }

  Future<void> showSystemNotifications(int leaves, int payrolls, int claims) async {
    if (kIsWeb) return;
    if (leaves > 0)   await _showNotification('Pending Leaves', 'You have $leaves pending leave requests');
    if (payrolls > 0) await _showNotification('Pending Payment Reports', 'You have $payrolls pending payment reports');
    if (claims > 0)   await _showNotification('Pending Claims', 'You have $claims pending claim requests');
  }

  Future<void> _showNotification(String title, String body) async {
    if (kIsWeb || flutterLocalNotificationsPlugin == null) return;
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'charms_hr_channel', 'CHARMS HR Notifications',
        importance: Importance.max, priority: Priority.high);
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin!.show(0, title, body, details);
  }

  // ── Part Timer Payment Claim Card ─────────────────────────────────────────
  Widget _buildPaymentClaimCard(PaymentClaim claim) {
    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(claim.year, claim.month),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header row ────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.payments_rounded,
                  color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  claim.staffName ?? 'Part Timer (ID: ${claim.staffId})',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
                Text('Part Timer Payment Claim',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Pending',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w700)),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Claim details ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              _claimDetailRow(
                  Icons.calendar_month_rounded,
                  'Month',
                  monthName,
                  Colors.blue),
              const SizedBox(height: 8),
              _claimDetailRow(
                  Icons.today_rounded,
                  'Days Worked',
                  '${claim.totalDays} day${claim.totalDays > 1 ? 's' : ''}',
                  Colors.teal),
              const SizedBox(height: 8),
              _claimDetailRow(
                  Icons.attach_money_rounded,
                  'Day Rate',
                  'RM ${claim.dayRate.toStringAsFixed(2)}',
                  Colors.green),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Claim',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF1E293B))),
                  Text(
                    'RM ${claim.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.orange),
                  ),
                ],
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // ── Approve / Reject buttons ──────────────────────────────
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _handleApproveClaim(claim),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _handleRejectClaim(claim),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _claimDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text('$label: ',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500)),
      Text(value,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color)),
    ]);
  }

  // ── Approve claim ─────────────────────────────────────────────────────────
  Future<void> _handleApproveClaim(PaymentClaim claim) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text('Approve Claim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Approve payment claim of RM ${claim.totalAmount.toStringAsFixed(2)} '
          'for ${claim.staffName ?? 'this staff'}?\n\n'
          'Payment will be marked as published.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Use staffId as reviewedBy (admin's ID) — ideally pass actual admin ID
    final claimProv =
        Provider.of<PaymentClaims>(context, listen: false);
    final success = await claimProv.approveClaim(claim.claimId, 1);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? '✅ Claim approved! Payment published.'
          : 'Failed to approve. Try again.'),
      backgroundColor: success ? Colors.green : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));

    if (success) {
      await claimProv.fetchAllClaims(status: 'Pending');
      setState(() {});
    }
  }

  // ── Reject claim ──────────────────────────────────────────────────────────
  Future<void> _handleRejectClaim(PaymentClaim claim) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
          SizedBox(width: 8),
          Text('Reject Claim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Reject payment claim for ${claim.staffName ?? 'this staff'}?',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text('Please provide a reason:',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Incomplete working days, data mismatch...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please provide a rejection reason.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final claimProv =
        Provider.of<PaymentClaims>(context, listen: false);
    final success =
        await claimProv.rejectClaim(claim.claimId, 1, reason);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? '❌ Claim rejected. Staff notified.'
          : 'Failed to reject. Try again.'),
      backgroundColor: success ? Colors.redAccent : Colors.grey,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));

    if (success) {
      await claimProv.fetchAllClaims(status: 'Pending');
      setState(() {});
    }
  }

  // ── Exchange card ─────────────────────────────────────────────────────────
  Widget _buildExchangeCard(ScheduleExchange exchange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.indigo, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Schedule Exchange Approval',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                Text('Both staff have agreed to swap',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              _exchangeRow(
                  label: exchange.requesterName ?? 'Staff A',
                  date: exchange.requesterWorkDate ?? '—',
                  time: exchange.requesterStartTime ?? '—',
                  dept: exchange.requesterDepartment,
                  workLocation: exchange.requesterWorkLocation,
                  icon: Icons.arrow_forward_rounded),
              const Divider(height: 16),
              _exchangeRow(
                  label: exchange.targetName ?? 'Staff B',
                  date: exchange.targetWorkDate ?? '—',
                  time: exchange.targetStartTime ?? '—',
                  dept: exchange.targetDepartment,
                  workLocation: exchange.targetWorkLocation,
                  icon: Icons.arrow_back_rounded),
            ]),
          ),
          if (exchange.requesterNote != null &&
              exchange.requesterNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: "${exchange.requesterNote}"',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => _hrRespondExchange(exchange, true),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Approve Swap',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => _hrRespondExchange(exchange, false),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject Swap',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _exchangeRow({
    required String label,
    required String date,
    required String time,
    String? dept,
    String? workLocation,
    required IconData icon,
  }) {
    String locationName(String? loc) {
      switch (loc) {
        case '1': return 'Chagar Hutang';
        case '2': return 'Turtle Lab';
        case '3': return 'UMT';
        default:  return '—';
      }
    }

    Color locationColor(String? loc) {
      switch (loc) {
        case '1': return const Color(0xFF0891B2);
        case '2': return const Color(0xFF7C3AED);
        case '3': return const Color(0xFFF59E0B);
        default:  return Colors.grey;
      }
    }

    return Row(children: [
      Icon(icon, size: 16, color: Colors.indigo),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12)),
          if (dept != null && dept.isNotEmpty)
            Text(dept,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.w600)),
          Text('$date  •  $time',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: locationColor(workLocation).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: locationColor(workLocation).withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on_rounded,
                  size: 11, color: locationColor(workLocation)),
              const SizedBox(width: 3),
              Text(locationName(workLocation),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: locationColor(workLocation))),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _hrRespondExchange(
      ScheduleExchange exchange, bool approve) async {
    String? hrNote;
    if (!approve) {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text('Reject Exchange',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Please provide a reason for rejecting:',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Schedule conflict, not enough staff...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      hrNote = reasonController.text.trim();
    }

    final success = await Provider.of<ScheduleExchanges>(context,
            listen: false)
        .hrRespond(exchange.exchangeId, approve, note: hrNote);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? approve
              ? '✅ Exchange approved! Schedules have been swapped.'
              : '❌ Exchange rejected.'
          : 'Failed. Try again.'),
      backgroundColor:
          success ? (approve ? Colors.green : Colors.redAccent) : Colors.grey,
    ));
    if (success) {
      await Provider.of<ScheduleExchanges>(context, listen: false)
          .fetchAllForHR();
      setState(() {});
    }
  }

  // ── Rejected schedule card ────────────────────────────────────────────────
  Widget _buildRejectedScheduleCard(Schedule schedule, List<Staff> staffList) {
    const branchNames = {1: 'Chagar Hutang', 2: 'Turtle Lab', 3: 'UMT'};
    final branch = branchNames[schedule.workLocation] ?? 'Unknown';
    final date   = DateFormat('dd MMM yyyy').format(schedule.workDate);

    final staff =
        staffList.where((s) => s.staffId == schedule.staffId).firstOrNull;
    final staffName = staff != null
        ? '${staff.firstname} ${staff.lastname}'.trim()
        : 'Staff ID: ${schedule.staffId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.cancel_rounded,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(staffName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text('$branch  •  $date',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                Text(
                    '${schedule.workStartTime} – ${schedule.workEndTime}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Not Accepted',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          if (schedule.staffNote != null &&
              schedule.staffNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Reason: "${schedule.staffNote}"',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () =>
                  _confirmDismissSchedule(schedule, staffName),
              icon: const Icon(Icons.check_circle_outline_rounded,
                  size: 16),
              label: const Text('Dismiss & Remove Shift',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDismissSchedule(
      Schedule schedule, String staffName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle_outline_rounded,
              color: Colors.redAccent, size: 20),
          SizedBox(width: 8),
          Text('Dismiss Schedule',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'Remove the rejected shift for $staffName from the schedule?\n\n'
          'The rejection will still appear in their Schedule History.',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await Provider.of<Schedules>(context, listen: false)
          .dismissSchedule(schedule.schedId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Shift removed from schedule. History preserved.'),
        backgroundColor: Colors.green,
      ));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to dismiss: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('NOTIFICATIONS',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Consumer<PaymentClaims>(
        builder: (context, paymentClaims, _) {
          return Consumer6<Leaves, Payments, Claims, ScheduleExchanges,
              Schedules, Staffs>(
            builder: (context, leaves, payments, claims, exchanges,
                schedules, staffs, child) {
              final pendingLeaves =
                  leaves.leaves.where((l) => l.status == 'Pending').toList();
              final pendingPayrolls = payments.payments
                  .where((p) => p.status == 'Pending')
                  .toList();
              final pendingClaims =
                  claims.claims.where((c) => c.status == 'Pending').toList();
              final pendingExchanges =
                  exchanges.exchanges.where((e) => e.status == 1).toList();
              final rejectedSchedules = schedules.schedules
                  .where((s) => s.acceptanceStatus == 2 && !s.hrDismissed)
                  .toList();

              // ✅ Part timer payment claims pending approval
              final pendingPaymentClaims = paymentClaims.pendingClaims;

              final hasAny = pendingLeaves.isNotEmpty ||
                  pendingPayrolls.isNotEmpty ||
                  pendingClaims.isNotEmpty ||
                  pendingExchanges.isNotEmpty ||
                  rejectedSchedules.isNotEmpty ||
                  pendingPaymentClaims.isNotEmpty;

              if (!hasAny) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No pending notifications',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                        left: 8.0, bottom: 16.0, top: 8.0),
                    child: Text('Action Required',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                  ),

                  // ── Part Timer Payment Claims ─────────────────────
                  if (pendingPaymentClaims.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, top: 4.0, bottom: 12.0),
                      child: Row(children: [
                        const Icon(Icons.payments_rounded,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Part Timer Payment Claims (${pendingPaymentClaims.length})',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                      ]),
                    ),
                    ...pendingPaymentClaims
                        .map((c) => _buildPaymentClaimCard(c)),
                  ],

                  // ── Leave requests ────────────────────────────────
                  ...pendingLeaves.map((leave) => NotificationItem(
                        title: 'Leave Request Pending',
                        subtitle:
                            'Staff ID: ${leave.staffId} • Type: ${leave.leaveType}',
                        iconData: Icons.beach_access_rounded,
                        iconColor: Colors.redAccent,
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ManageLeaveScreen()));
                          setState(() {});
                        },
                      )),

                  // ── Payroll ───────────────────────────────────────
                  ...pendingPayrolls.map((payroll) => NotificationItem(
                        title: 'Payment Report Pending',
                        subtitle: 'Staff ID: ${payroll.staffId}',
                        iconData: Icons.receipt_long_rounded,
                        iconColor: Colors.teal,
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ManagePayrollScreen()));
                          setState(() {});
                        },
                      )),

                  // ── Claims ────────────────────────────────────────
                  ...pendingClaims.map((claim) => NotificationItem(
                        title: 'Claim Request Pending',
                        subtitle:
                            'Staff ID: ${claim.staffId} • Amount: RM${claim.amount}',
                        iconData: Icons.request_page_rounded,
                        iconColor: Colors.orange,
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ManageClaimScreen()));
                          setState(() {});
                        },
                      )),

                  // ── Rejected schedules ────────────────────────────
                  if (rejectedSchedules.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(
                          left: 8.0, top: 8.0, bottom: 12.0),
                      child: Row(children: [
                        Icon(Icons.cancel_rounded,
                            color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Rejected Schedules',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                      ]),
                    ),
                    ...rejectedSchedules.map((s) =>
                        _buildRejectedScheduleCard(s, staffs.staffList)),
                  ],

                  // ── Exchange approvals ────────────────────────────
                  if (pendingExchanges.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(
                          left: 8.0, top: 8.0, bottom: 12.0),
                      child: Row(children: [
                        Icon(Icons.swap_horiz_rounded,
                            color: Colors.indigo, size: 18),
                        SizedBox(width: 8),
                        Text('Schedule Exchange Approvals',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                      ]),
                    ),
                    ...pendingExchanges
                        .map((e) => _buildExchangeCard(e)),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Notification Item ─────────────────────────────────────────────────────────
class NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}