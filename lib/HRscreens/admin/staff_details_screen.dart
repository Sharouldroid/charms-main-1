import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/HRmodels/staff.dart';
import 'package:charms/HRproviders/staffs.dart';
import 'package:charms/HRscreens/admin/edit_staff_screen.dart';

class StaffDetailsScreen extends StatelessWidget {
  final Staff staff;

  const StaffDetailsScreen({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    String gender = staff.emergencyGender == 1 ? 'Male' : 'Female';
    String maritalStatus = staff.maritalStatus == 1 ? 'Single' : 'Married';

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
            // ✅ Profile photo with proper filepath
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                backgroundImage: (staff.filepath != null &&
                        staff.filepath!.isNotEmpty)
                    ? NetworkImage(
                        'https://devcms.com.my/charmsAPI/public/storage/${staff.filepath}',
                      )
                    : null,
                child: (staff.filepath == null || staff.filepath!.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "Personal Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            DetailsRow(label: "Staff ID", value: "${staff.staffId}"),
            DetailsRow(
                label: "Name",
                value: "${staff.firstname} ${staff.lastname}"),
            DetailsRow(label: "IC Number", value: staff.idNum),
            DetailsRow(label: "Date of Birth", value: staff.dob),
            DetailsRow(label: "Nationality", value: staff.nationality),
            DetailsRow(label: "Religion", value: staff.religion),
            DetailsRow(label: "Gender", value: gender),
            DetailsRow(label: "Marital Status", value: maritalStatus),
            const SizedBox(height: 20),

            const Text(
              "Address Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            DetailsRow(
                label: "Address",
                value: "${staff.address1}, ${staff.address2}"),
            DetailsRow(label: "City", value: staff.city),
            DetailsRow(label: "State", value: staff.state),
            DetailsRow(label: "Country", value: staff.country),
            DetailsRow(label: "Phone", value: staff.phone),
            DetailsRow(
                label: "Office Phone", value: staff.officePhone ?? 'N/A'),
            DetailsRow(label: "Email", value: staff.email),
            DetailsRow(label: "Occupation", value: staff.occupation),
            const SizedBox(height: 20),

            const Text(
              "Emergency Contact Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            DetailsRow(label: "Emergency Name", value: staff.emergencyName),
            DetailsRow(label: "Emergency IC", value: staff.emergencyIc),
            DetailsRow(
                label: "Emergency Relation", value: staff.emergencyRelation),
            DetailsRow(label: "Emergency Gender", value: gender),
            DetailsRow(label: "Emergency Phone", value: staff.emergencyPhone),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStaffScreen(staff: staff),
                      ),
                    );
                  },
                  child: const Text('Edit Staff',
                      style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(context),
                  child: const Text('Delete Staff',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to delete this staff member?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteStaff(context);
              },
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStaff(BuildContext context) async {
    final staffProvider = Provider.of<Staffs>(context, listen: false);

    try {
      await staffProvider.deleteStaff(staff.staffId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff deleted successfully!')),
      );

      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete staff: $error')),
      );
    }
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
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
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