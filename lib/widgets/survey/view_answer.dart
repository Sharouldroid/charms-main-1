import 'package:charms/models/survey.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:charms/providers/surveys.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;

class ViewAnswer extends StatelessWidget {
  const ViewAnswer({
    super.key,
    required this.hostname,
    required this.userid,
    required this.confirmnum,
  });

  final String hostname;
  final int userid;
  final int confirmnum;
  Future<void> _captureAndSharePng(BuildContext context) async {
    try {
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        // Create PDF document
        final pdf = pw.Document();

        // Embed the image in the PDF
        final imageProvider = pw.MemoryImage(pngBytes);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Image(imageProvider); // Add the image to the page
            },
          ),
        );

        // Use the Printing package to print the PDF
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          format: PdfPageFormat.a4,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating print: ${e.toString()}')),
      );
    }
  }

  Widget _buildSurveySection({
    required String title,
    required List<SurveyAnswer> answers,
    bool isLast = false,
  }) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            answers.isNotEmpty
                ? Column(
                  children:
                      answers
                          .map(
                            (answer) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    answer.questionText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    answer.surveyanswer,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (answers.last != answer)
                                    const Divider(height: 24),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                )
                : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No answers available',
                    style: TextStyle(color: Colors.grey),
                  ),
                  // if (!isLast) const SizedBox(height: 24),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Answers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _captureAndSharePng(context),
            tooltip: 'Print Survey Answers',
          ),
        ],
      ),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              // Header with confirmation number
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      'Confirmation Number: $confirmnum',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Entry Survey
              FutureBuilder(
                future: Provider.of<Surveys>(
                  context,
                  listen: false,
                ).fetchEntrySurveywithQuestion(hostname, userid, confirmnum),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        // 'Error loading entry survey: ${snapshot.error}',
                        'Error loading entry survey: No attempted answers',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return Consumer<Surveys>(
                    builder:
                        (ctx, surveydata, _) => _buildSurveySection(
                          title: 'Entry Survey Answers',
                          answers: surveydata.entryanswer,
                        ),
                  );
                },
              ),

              // Exit Survey
              FutureBuilder(
                future: Provider.of<Surveys>(
                  context,
                  listen: false,
                ).fetchExitSurveywithQuestion(hostname, userid, confirmnum),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        // 'Error loading entry survey: ${snapshot.error}',
                        'Error loading entry survey: No attempted answers',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return Consumer<Surveys>(
                    builder:
                        (ctx, surveydata, _) => _buildSurveySection(
                          title: 'Exit Survey Answers',
                          answers: surveydata.exitanswer,
                          isLast: true,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
