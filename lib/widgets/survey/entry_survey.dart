import 'package:charms/providers/surveys.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

class EntrySurvey extends StatefulWidget {
  const EntrySurvey({
    super.key,
    required this.eventname,
    required this.hostname,
    required this.userid,
    required this.eventid,
    required this.confirmnum,
  });

  final String eventname;
  final String hostname;
  final int userid;
  final int eventid;
  final int confirmnum;

  @override
  _EntrySurveyState createState() => _EntrySurveyState();
}

class _EntrySurveyState extends State<EntrySurvey> {
  Map<int, dynamic> combinedAnswers = {}; // Map with custom keys
  Map<int, TextEditingController> textControllers = {}; // TextField controllers
  final GlobalKey<FormState> _formKey = GlobalKey();
  var _isLoading = false;

  // Define the dual-language labels
  final List<String> _ratingLabels = [
    "Sangat Tidak Memuaskan (Strongly Disagree)",
    "Kurang Memuaskan (Disagree)",
    "Memuaskan (Neutral)",
    "Baik (Good)",
    "Sangat Baik (Very Good)",
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<Surveys>(context, listen: false).answerEntrySurvey(
        widget.hostname,
        combinedAnswers,
        widget.userid,
        widget.eventid,
        widget.confirmnum,
      );
    } catch (error) {
      showSimpleNotification(
        Text(
          'Error! $error',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        duration: const Duration(seconds: 4),
        background: Colors.red,
      );
    }
    setState(() {
      _isLoading = false;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.eventname} Entry Survey')),
      body: FutureBuilder(
        future: Provider.of<Surveys>(
          context,
          listen: false,
        ).fetchSurveybyType(widget.hostname, 1, 1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.error != null) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Form(
                key: _formKey,
                child: Consumer<Surveys>(
                  builder:
                      (ctx, surveydata, child) =>
                          surveydata.surveylist.isNotEmpty
                              ? ListView.builder(
                                itemCount: surveydata.surveylist.length,
                                itemBuilder: (_, questionIndex) {
                                  final survey =
                                      surveydata.surveylist[questionIndex];
                                  final int questionId =
                                      survey.id; // Use `id` as key

                                  return ListTile(
                                    isThreeLine: true,
                                    title: Text(survey.question),
                                    subtitle: StatefulBuilder(
                                      builder: (context, setInnerState) {
                                        return survey.questiontype == 1
                                            ? Column(
                                              children: List.generate(
                                                survey.ratingcount,
                                                (ratingIndex) =>
                                                    RadioListTile<int>(
                                                      value: ratingIndex + 1,
                                                      groupValue:
                                                          combinedAnswers[questionId],
                                                      contentPadding: EdgeInsets.zero,
                                                      onChanged: (value) {
                                                        setInnerState(() {
                                                          combinedAnswers[questionId] =
                                                              value!;
                                                        });
                                                      },
                                                      // UPDATED TITLE WITH ADAPTIVE LAYOUT
                                                      title: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            '${ratingIndex + 1}',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              ratingIndex <
                                                                      _ratingLabels.length
                                                                  ? _ratingLabels[ratingIndex]
                                                                  : '',
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow.visible,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                              ),
                                            )
                                            : Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                      hintText:
                                                          'Your answer here',
                                                    ),
                                                maxLines: 2,
                                                onChanged: (value) {
                                                  combinedAnswers[questionId] =
                                                      value;
                                                },
                                              ),
                                            );
                                      },
                                    ),
                                  );
                                },
                              )
                              : Center(
                                child: const Text('No entry survey available'),
                              ),
                ),
              );
            }
          }
        },
      ),
      floatingActionButton:
          _isLoading
              ? const CircularProgressIndicator()
              : FloatingActionButton(
                onPressed: () {
                  _submit();
                },
                child: const Icon(Icons.send),
              ),
    );
  }
}