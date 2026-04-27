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

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this staff member?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // close dialog
                await _deleteStaff();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStaff() async {
    debugPrint('🔴 _deleteStaff called');
    final staffProvider = Provider.of<Staffs>(context, listen: false);

    try {
      await staffProvider.deleteStaff(widget.staff.staffId);
      debugPrint('✅ deleteStaff() done');

      // ✅ No mounted check needed — StatefulWidget manages this
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff deleted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop(true);
      debugPrint('✅ pop(true) called');
    } catch (error) {
      debugPrint('❌ Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete staff: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String gender = widget.staff.emergencyGender == 1 ? 'Male' : 'Female';
    String maritalStatus = widget.staff.maritalStatus == 1 ? 'Single' : 'Married';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Staff Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                backgroundImage: (widget.staff.filepath != null &&
                        widget.staff.filepath!.isNotEmpty)
                    ? NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/${widget.staff.filepath}',
                      )
                    : null,
                child: (widget.staff.filepath == null || widget.staff.filepath!.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            const Text("Personal Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            DetailsRow(label: "Staff ID", value: "${widget.staff.staffId}"),
            DetailsRow(label: "Name", value: "${widget.staff.firstname} ${widget.staff.lastname}"),
            DetailsRow(label: "IC Number", value: widget.staff.idNum),
            DetailsRow(label: "Date of Birth", value: widget.staff.dob),
            DetailsRow(label: "Nationality", value: widget.staff.nationality),
            DetailsRow(label: "Religion", value: widget.staff.religion),
            DetailsRow(label: "Gender", value: gender),
            DetailsRow(label: "Marital Status", value: maritalStatus),
            const SizedBox(height: 20),

            const Text("Address Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            DetailsRow(label: "Address", value: "${widget.staff.address1}, ${widget.staff.address2}"),
            DetailsRow(label: "City", value: widget.staff.city),
            DetailsRow(label: "State", value: widget.staff.state),
            DetailsRow(label: "Country", value: widget.staff.country),
            DetailsRow(label: "Phone", value: widget.staff.phone),
            DetailsRow(label: "Office Phone", value: widget.staff.officePhone ?? 'N/A'),
            DetailsRow(label: "Email", value: widget.staff.email),
            DetailsRow(label: "Occupation", value: widget.staff.occupation),
            const SizedBox(height: 20),

            const Text("Emergency Contact Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            DetailsRow(label: "Emergency Name", value: widget.staff.emergencyName),
            DetailsRow(label: "Emergency IC", value: widget.staff.emergencyIc),
            DetailsRow(label: "Emergency Relation", value: widget.staff.emergencyRelation),
            DetailsRow(label: "Emergency Gender", value: gender),
            DetailsRow(label: "Emergency Phone", value: widget.staff.emergencyPhone),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStaffScreen(staff: widget.staff),
                      ),
                    );
                  },
                  child: const Text('Edit Staff', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _showDeleteConfirmationDialog,
                  child: const Text('Delete Staff', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailsRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}