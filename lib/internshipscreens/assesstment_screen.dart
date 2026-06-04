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
  final Map<String, String> criterionLabels = {
    'criterion_1': 'Communication Skills',
    'criterion_2': 'Problem Solving',
    'criterion_3': 'Teamwork',
    'criterion_4': 'Punctuality',
    'criterion_5': 'Adaptability',
  };

  final Map<String, IconData> criterionIcons = {
    'criterion_1': Icons.record_voice_over,
    'criterion_2': Icons.lightbulb,
    'criterion_3': Icons.group,
    'criterion_4': Icons.access_time,
    'criterion_5': Icons.sync_alt,
  };

  String _getRatingLabel(int value) {
    switch (value) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  Color _getRatingColor(int value) {
    switch (value) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.blueAccent;
    }
  }

  double _getAverage(Map<String, int> ratings) {
    if (ratings.isEmpty) return 0;
    return ratings.values.reduce((a, b) => a + b) / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    final ratings = Provider.of<AssessmentProvider>(context).ratings;

    if (ratings.isEmpty) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

    final average = _getAverage(ratings);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rate Intern'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Color.fromARGB(255, 123, 64, 251)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evaluate the Intern',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rate each criterion from 1 (Poor) to 5 (Excellent)',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Overall average
                  Row(
                    children: [
                      const Icon(Icons.star_rate, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Current Average: ${average.toStringAsFixed(1)} / 5.0',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Criterion cards
            ...ratings.keys.map((criterion) {
              final label = criterionLabels[criterion] ??
                  criterion.replaceAll('_', ' ').capitalize();
              final icon = criterionIcons[criterion] ?? Icons.star;
              final value = ratings[criterion] ?? 1;
              final color = _getRatingColor(value);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: Colors.blueAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color),
                          ),
                          child: Text(
                            '$value — ${_getRatingLabel(value)}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: color,
                        inactiveTrackColor: color.withOpacity(0.2),
                        thumbColor: color,
                        overlayColor: color.withOpacity(0.15),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                        valueIndicatorTextStyle:
                            const TextStyle(color: Colors.white),
                      ),
                      child: Slider(
                        min: 1,
                        max: 5,
                        value: value.toDouble(),
                        divisions: 4,
                        label: '$value',
                        onChanged: (val) {
                          Provider.of<AssessmentProvider>(context,
                                  listen: false)
                              .setRating(criterion, val.toInt());
                        },
                      ),
                    ),

                    // Scale labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent']
                            .map((e) => Text(
                                  e,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Provider.of<AssessmentProvider>(context, listen: false)
                      .submitAssessment(widget.internId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assessment submitted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Submit Assessment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}