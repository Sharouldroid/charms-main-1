import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/surveys.dart';
import 'package:charms/widgets/survey/create_feedback.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class SurveyList extends StatelessWidget {
  const SurveyList({
    super.key,
    required this.admin,
    required this.userid,
    required this.hostname,
    required this.isLabOfficer,
  });

  final bool admin;
  final int userid;
  final String hostname;
  final bool isLabOfficer;

  // Future<void> _captureAndPrint(BuildContext context) async {
  //   try {
  //     final surveys = Provider.of<Surveys>(context, listen: false).surveylist;

  //     final pdf = pw.Document();
  //     pdf.addPage(
  //       pw.Page(
  //         build: (pw.Context context) {
  //           return pw.Column(
  //             crossAxisAlignment: pw.CrossAxisAlignment.start,
  //             children: [
  //               pw.Text(
  //                 'Survey Questions',
  //                 style: pw.TextStyle(
  //                   fontSize: 12,
  //                   fontWeight: pw.FontWeight.bold,
  //                 ),
  //               ),
  //               pw.SizedBox(height: 10),
  //               ...surveys.map(
  //                 (survey) => pw.Column(
  //                   crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                   children: [
  //                     pw.Text(
  //                       survey.question,
  //                       style: pw.TextStyle(fontSize: 10),
  //                     ),
  //                     pw.SizedBox(height: 5),
  //                     pw.Text(
  //                       'Type: ${survey.questiontype == 1 ? 'Rating Question' : 'Text Question'}',
  //                       style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
  //                     ),
  //                     // pw.Text(
  //                     //   'Survey: ${getSurveyType(survey.surveytype)}',
  //                     //   style: pw.TextStyle(
  //                     //     fontSize: 14,
  //                     //     color: PdfColors.grey,
  //                     //   ),
  //                     // ),
  //                     // pw.Text(
  //                     //   'For: ${survey.surveyfor == 1 ? 'Volunteer' : 'Researcher'}',
  //                     //   style: pw.TextStyle(
  //                     //     fontSize: 14,
  //                     //     color: PdfColors.grey,
  //                     //   ),
  //                     // ),
  //                     // pw.Text(
  //                     //   'Status: ${survey.status == 1 ? 'Active' : 'Inactive'}',
  //                     //   style: pw.TextStyle(
  //                     //     fontSize: 10,
  //                     //     color: PdfColors.grey,
  //                     //   ),
  //                     // ),
  //                     pw.Divider(),
  //                     pw.SizedBox(height: 20),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     );

  //     await Printing.layoutPdf(
  //       onLayout: (format) async => pdf.save(),
  //       format: PdfPageFormat.a4,
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error generating print: ${e.toString()}')),
  //     );
  //   }
  // }
  Future<void> _captureAndPrint(BuildContext context) async {
    try {
      final surveys = Provider.of<Surveys>(context, listen: false).surveylist;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          // Changed from pw.Page to pw.MultiPage
          margin: const pw.EdgeInsets.all(20),
          // pageTheme: const pw.PageTheme(textDirection: pw.TextDirection.ltr),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Survey Questions',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              ...surveys.map(
                (survey) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      survey.question,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Type: ${survey.questiontype == 1 ? 'Rating Question' : 'Text Question'}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                    ),
                    pw.Divider(),
                    pw.SizedBox(height: 20),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating print: ${e.toString()}')),
      );
    }
  }

  String getSurveyType(int type) {
    switch (type) {
      case 1:
        return 'Entry Survey';
      case 2:
        return 'Exit Survey';
      default:
        return 'Entry and Exit Survey';
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> deleteSurvey(int surveyId) async {
      final url = '${hostname}survey/delete/$surveyId';

      try {
        final response = await http.delete(Uri.parse(url));

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Survey deleted successfully')),
          );
          // Refresh the survey list
          Provider.of<Surveys>(
            context,
            listen: false,
          ).fetchAllSurveys(hostname);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete survey: $e')));
      }
    }

    return FutureBuilder(
      future: Provider.of<Surveys>(
        context,
        listen: false,
      ).fetchAllSurveys(hostname),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          if (snapshot.error != null) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Consumer<Surveys>(
              builder:
                  (ctx, surveydata, child) => RepaintBoundary(
                    key: GlobalKey(), // Provide a unique key for the boundary
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: surveydata.surveylist.length,
                            itemBuilder:
                                (_, i) => ListTile(
                                  title: Text(
                                    surveydata.surveylist[i].question,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            surveydata
                                                        .surveylist[i]
                                                        .questiontype ==
                                                    1
                                                ? 'Rating Question'
                                                : 'Text Question',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            surveydata
                                                        .surveylist[i]
                                                        .surveytype ==
                                                    1
                                                ? '| Entry Survey'
                                                : surveydata
                                                        .surveylist[i]
                                                        .surveytype ==
                                                    2
                                                ? '| Exit Survey'
                                                : '| Entry and Exit Survey',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            surveydata
                                                        .surveylist[i]
                                                        .surveyfor ==
                                                    1
                                                ? 'Volunteer'
                                                : 'Researcher',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            surveydata.surveylist[i].status == 1
                                                ? '| Active'
                                                : '| Inactive',
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing:
                                      isLabOfficer == false
                                          ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      context,
                                                    ).push(
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              ctx,
                                                            ) => CreateFeedback(
                                                              userid: userid,
                                                              hostname:
                                                                  hostname,
                                                              survey:
                                                                  surveydata
                                                                      .surveylist,
                                                              surveyid:
                                                                  surveydata
                                                                      .surveylist[i]
                                                                      .id,
                                                              index: i,
                                                            ),
                                                      ),
                                                    ),
                                                icon: const Icon(Icons.edit),
                                              ),

                                              IconButton(
                                                onPressed:
                                                    () => deleteSurvey(
                                                      surveydata
                                                          .surveylist[i]
                                                          .id,
                                                    ),
                                                icon: const Icon(Icons.delete),
                                              ),
                                            ],
                                          )
                                          : const SizedBox.shrink(),
                                ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _captureAndPrint(context),
                          child: const Text('Print Survey Questions'),
                        ),
                      ],
                    ),
                  ),
            );
          }
        }
      },
    );
  }
}
