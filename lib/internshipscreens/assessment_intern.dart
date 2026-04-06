import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/assessment_provider.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class AssessmentInternPage extends StatefulWidget {
  final int internId;

  const AssessmentInternPage({super.key, required this.internId});

  @override
  _AssessmentInternPageState createState() => _AssessmentInternPageState();
}

class _AssessmentInternPageState extends State<AssessmentInternPage> {
  @override
  void initState() {
    super.initState();
    // Load assessment data when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssessmentProvider>(context, listen: false)
          .loadAssessmentData(widget.internId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessmentProvider = Provider.of<AssessmentProvider>(context);
    final ratings = assessmentProvider.ratings;
    final isLoading = assessmentProvider.isLoading;
    final errorMessage = assessmentProvider.errorMessage;

    // Map for custom labels for each criterion
    final Map<String, String> criterionLabels = {
      'criterion_1': 'Communication Skills',
      'criterion_2': 'Problem Solving',
      'criterion_3': 'Teamwork',
      'criterion_4': 'Punctuality',
      'criterion_5': 'Adaptability',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Your Marks'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    const Text(
                      "Your Performance Overview",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Show error message if any
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Check if ratings are available
                    if (ratings.isNotEmpty && errorMessage == null)
                      ...ratings.keys.map((criterion) {
                        String label = criterionLabels[criterion] ??
                            criterion.replaceAll('_', ' ').capitalize();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${ratings[criterion]} / 5',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }),

                    // Overall Performance Section
                    if (ratings.isNotEmpty && errorMessage == null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Overall Performance",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Display average rating
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rate,
                              color: Colors.orange,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _calculateAverage(ratings).toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              ' / 5.0',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Reload button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<AssessmentProvider>(context,
                                  listen: false)
                              .loadAssessmentData(widget.internId);
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Reload Assessment',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 32.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  double _calculateAverage(Map<String, int> ratings) {
    if (ratings.isEmpty) return 0.0;
    int sum = ratings.values.reduce((a, b) => a + b);
    return sum / ratings.length;
  }
}
