import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class StaffPayrollDetailsScreen extends StatelessWidget {
  final String month;
  final int year;
  final String staffId;
  final String staffName;
  final String workingDays;
  final double basicPay;
  final double totalBonus;
  final double totalDeduction;
  final double totalSalary;

  StaffPayrollDetailsScreen({
    required this.month,
    required this.year,
    required this.staffId,
    required this.staffName,
    required this.workingDays,
    required this.basicPay,
    required this.totalBonus,
    required this.totalDeduction,
    required this.totalSalary,
  });

  Future<void> _generateAndDownloadPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('SEATRU/CMS Payslip'),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Period: $month $year'),
              pw.SizedBox(height: 10),
              pw.Text('Staff ID: $staffId'),
              pw.Text('Name: $staffName'),
              pw.Text('Working Days: $workingDays'),
              pw.Text('Basic Pay: RM $basicPay'),
              pw.Text('Total Bonus: $totalBonus'),
              pw.Text('Total Deduction: $totalDeduction'),
              pw.SizedBox(height: 20),
              pw.Text('Total Payment: RM $totalSalary'),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Staff Signature'),
                  pw.Text('Manager Signature'),
                ],
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/payslip_${month.toLowerCase()}_$year.pdf');
    await file.writeAsBytes(await pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payroll Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'SEATRU X CMS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Payslip for $month $year',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Divider(),
                    DetailRow(label: 'Staff ID', value: staffId),
                    DetailRow(label: 'Name', value: staffName),
                    DetailRow(label: 'Working Days', value: workingDays),
                    DetailRow(
                      label: 'Basic Pay',
                      value: 'RM ${basicPay.toStringAsFixed(2)}'
                    ),DetailRow(
                      label: 'Total Bonus',
                      value: 'RM ${totalBonus.toStringAsFixed(2)}'
                    ),
                    DetailRow(
                      label: 'Total Deduction',
                      value: 'RM ${totalDeduction.toStringAsFixed(2)}'
                    ),
                    Divider(),
                    DetailRow(
                      label: 'Total Salary',
                      value: 'RM ${totalSalary.toStringAsFixed(2)}'
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'This is a computer Generated PaySlip. Signature is not required',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _generateAndDownloadPDF,
          icon: Icon(Icons.download),
          label: Text('Download PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  DetailRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
