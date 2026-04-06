import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/internshipproviders/assessment_provider.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class NextPage extends StatefulWidget {
  final int internId;

  const NextPage({super.key, required this.internId});

  @override
  _NextPageState createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  // Map for custom labels for each criterion
  final Map<String, String> criterionLabels = {
    'criterion_1': 'Communication Skills',
    'criterion_2': 'Problem Solving',
    'criterion_3': 'Teamwork',
    'criterion_4': 'Punctuality',
    'criterion_5': 'Adaptability',
  };

  @override
  Widget build(BuildContext context) {
    final ratings = Provider.of<AssessmentProvider>(context).ratings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Intern'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading
              const Text(
                "Evaluate the Intern",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              // Map over the criteria and display the custom labels
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
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blueAccent,
                        inactiveTrackColor: Colors.blueAccent.shade100,
                        thumbColor: Colors.blueAccent,
                        overlayColor: Colors.blueAccent.withOpacity(0.2),
                        valueIndicatorTextStyle:
                            const TextStyle(color: Colors.white),
                      ),
                      child: Slider(
                        min: 1,
                        max: 5,
                        value: ratings[criterion]!.toDouble(),
                        divisions: 4,
                        label: ratings[criterion].toString(),
                        onChanged: (value) {
                          Provider.of<AssessmentProvider>(context,
                                  listen: false)
                              .setRating(criterion, value.toInt());
                        },
                      ),
                    ),
                    // Properly aligned numbers below the slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        return Expanded(
                          child: Text(
                            (index + 1).toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }),
              const SizedBox(height: 20),
              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await Provider.of<AssessmentProvider>(context,
                            listen: false)
                        .submitAssessment(widget.internId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assessment submitted successfully!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Submit Assessment',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
