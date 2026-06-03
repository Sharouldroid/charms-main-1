import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRscreens/admin/edit_staff_screen.dart';

class StaffDetailsScreen extends StatefulWidget {
  final Staff staff;

  const StaffDetailsScreen({super.key, required this.staff});

  @override
  State<StaffDetailsScreen> createState() => _StaffDetailsScreenState();
}

class _StaffDetailsScreenState extends State<StaffDetailsScreen> {
  final Color bgColor    = const Color(0xFFF4F7FA);
  final Color primaryBlue = const Color(0xFF2563EB);

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete this staff member?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteStaff();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStaff() async {
    final staffProvider = Provider.of<Staffs>(context, listen: false);
    try {
      await staffProvider.deleteStaff(widget.staff.staffId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff deleted successfully!'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete staff: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: use widget.staff.gender (not emergencyGender) for staff gender
    final String staffGender         = widget.staff.gender == 1 ? 'Male' : 'Female';
    // ✅ FIX: separate variable for emergency contact gender
    final String emergencyGender     = widget.staff.emergencyGender == 1 ? 'Male' : 'Female';
    final String maritalStatus       = widget.staff.maritalStatus == 1 ? 'Single' : 'Married';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'STAFF DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Profile Header Card ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: primaryBlue.withOpacity(0.2), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: (widget.staff.filepath != null &&
                                widget.staff.filepath!.isNotEmpty)
                            ? NetworkImage(
                                'https://devcms.com.my/charmsAPI/public/storage/${widget.staff.filepath}',
                              )
                            : null,
                        child: (widget.staff.filepath == null ||
                                widget.staff.filepath!.isEmpty)
                            ? Icon(Icons.person_rounded,
                                size: 50, color: Colors.blue.shade200)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.staff.firstname} ${widget.staff.lastname}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.staff.occupation,
                      style: TextStyle(
                        fontSize: 15,
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Staff ID: ${widget.staff.staffId}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Personal Details ───────────────────────────────────────────
            _buildInfoCard('Personal Details', Icons.badge_rounded, [
              DetailsRow(label: 'IC Number',     value: widget.staff.idNum),
              DetailsRow(label: 'Date of Birth', value: widget.staff.dob),
              DetailsRow(label: 'Nationality',   value: widget.staff.nationality),
              DetailsRow(label: 'Religion',      value: widget.staff.religion),
              // ✅ FIX: shows staff's own gender
              DetailsRow(label: 'Gender',        value: staffGender),
              DetailsRow(label: 'Marital Status', value: maritalStatus),
            ]),

            // ── Contact & Address ──────────────────────────────────────────
            _buildInfoCard('Contact & Address', Icons.location_on_rounded, [
              DetailsRow(label: 'Phone',        value: widget.staff.phone),
              DetailsRow(label: 'Office Phone', value: widget.staff.officePhone ?? 'N/A'),
              DetailsRow(label: 'Email',        value: widget.staff.email),
              DetailsRow(label: 'Address',      value: '${widget.staff.address1}, ${widget.staff.address2}'),
              DetailsRow(label: 'City',         value: widget.staff.city),
              DetailsRow(label: 'State',        value: widget.staff.state),
              DetailsRow(label: 'Country',      value: widget.staff.country),
            ]),

            // ── Emergency Contact ──────────────────────────────────────────
            _buildInfoCard('Emergency Contact', Icons.health_and_safety_rounded, [
              DetailsRow(label: 'Name',     value: widget.staff.emergencyName),
              DetailsRow(label: 'IC Number', value: widget.staff.emergencyIc),
              DetailsRow(label: 'Relation', value: widget.staff.emergencyRelation),
              // ✅ FIX: uses emergencyGender, not staffGender
              DetailsRow(label: 'Gender',   value: emergencyGender),
              DetailsRow(label: 'Phone',    value: widget.staff.emergencyPhone),
            ]),

            const SizedBox(height: 8),

            // ── Action Buttons ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      foregroundColor: primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditStaffScreen(staff: widget.staff),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Staff',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showDeleteConfirmationDialog,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Staff',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Modernized Details Row
class DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailsRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}