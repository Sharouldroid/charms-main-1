import 'package:charms/models/user.dart';
import 'package:charms/widgets/survey/create_feedback.dart';
import 'package:charms/widgets/survey/survey_list.dart';
import 'package:charms/widgets/survey/event_list.dart';
import 'package:flutter/material.dart';

class FeedbackAdminScreen extends StatelessWidget {
  const FeedbackAdminScreen({
    super.key,
    required this.isadmin,
    required this.user,
    required this.hostname,
    required this.isLabOfficer,
  });

  final bool isadmin;
  final User user;
  final String hostname;
  final bool isLabOfficer;

  // Future<void> _printAllQuestions(BuildContext context) async {
  //   // Implement your PDF generation and printing logic here
  //   final pdf = pw.Document();

  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) {
  //         return pw.Center(
  //           child: pw.Text('All Survey Questions PDF'),
  //         );
  //       },
  //     ),
  //   );

  //   await Printing.layoutPdf(
  //     onLayout: (PdfPageFormat format) async => pdf.save(),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final bool showAdminFeatures = isadmin && !isLabOfficer;
    // final bool showPrintFeatures = isLabOfficer;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Surveys'),
          actions: [
            if (showAdminFeatures)
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => CreateFeedback(
                      userid: 0,
                      hostname: hostname,
                      survey: const [],
                      surveyid: 0,
                      index: 0,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                tooltip: 'Add New Survey',
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(child: Text('Survey Questions')),
              Tab(child: Text('Survey Answers')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SurveyList(
              admin: isadmin,
              userid: int.parse(user.id),
              hostname: hostname,
              isLabOfficer: isLabOfficer,
            ),
            EventList(
              admin: isadmin,
              userid: int.parse(user.id),
              hostname: hostname,
              isLabOfficer: isLabOfficer,
            ),
          ],
        ),
      ),
    );
  }
}
