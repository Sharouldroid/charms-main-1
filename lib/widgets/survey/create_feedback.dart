import 'package:charms/models/survey.dart';
import 'package:charms/providers/surveys.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateFeedback extends StatefulWidget {
  const CreateFeedback({
    super.key,
    required this.userid,
    required this.hostname,
    required this.survey,
    required this.surveyid,
    required this.index,
  });

  final int userid;
  final String hostname;
  final List<Survey> survey;
  final int surveyid;
  final int index;

  @override
  State<CreateFeedback> createState() => _CreateFeedbackState();
}

class _CreateFeedbackState extends State<CreateFeedback> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  var _newSurvey = Survey(
    id: 0,
    question: '',
    questiontype: 1,
    ratingcount: 5,
    surveytype: 1,
    surveyfor: 1,
  );

  var _initValues = {
    'id': '',
    'question': '',
    'questiontype': '',
    'ratingcount': '',
    'surveytype': '',
    'surveyfor': '',
  };

  var _isLoading = false;
  var _isInit = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      if (widget.surveyid != 0) {
        _initValues = {
          'id': widget.surveyid.toString(),
          'question': widget.survey[widget.index].question,
          'questiontype': widget.survey[widget.index].questiontype.toString(),
          'ratingcount': widget.survey[widget.index].ratingcount.toString(),
          'surveytype': widget.survey[widget.index].surveytype.toString(),
          'surveyfor': widget.survey[widget.index].surveyfor.toString(),
        };
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _showErrorDialog(String message, int type) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              type == 1 ? 'Warning' : 'Message',
            ), // 1 = error, 2 = success
            content: Text(message),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Okay'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });
    if (widget.surveyid == 0) {
      try {
        // print(_authData);
        await Provider.of<Surveys>(
          context,
          listen: false,
        ).createSurvey(widget.hostname, _newSurvey, widget.userid);
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    } else {
      try {
        // print(_authData);
        await Provider.of<Surveys>(context, listen: false).updateSurvey(
          widget.hostname,
          _newSurvey,
          widget.userid,
          widget.surveyid,
        );
      } catch (error) {
        _showErrorDialog(error.toString(), 1);
      }
    }
    setState(() {
      _isLoading = false;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    int surveytype = 1;
    int questiontype = 1;
    int surveytarget = 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surveyid == 0 ? 'Create Survey' : 'Update Survey'),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                maxLines: 3,
                initialValue: _initValues['question'],
                decoration: const InputDecoration(labelText: 'Question'),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
                onSaved: (value) {
                  _newSurvey = Survey(
                    id: _newSurvey.id,
                    question: value!,
                    questiontype: _newSurvey.questiontype,
                    ratingcount: _newSurvey.ratingcount,
                    surveytype: _newSurvey.surveytype,
                    surveyfor: _newSurvey.surveyfor,
                  );
                },
              ),
              DropdownButtonFormField<dynamic>(
                initialValue:
                    _initValues['questiontype']!.isNotEmpty
                        ? int.parse(_initValues['questiontype'].toString())
                        : null,
                hint: const Text('Question Type'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Rating')),
                  DropdownMenuItem(value: 2, child: Text('Text')),
                ],
                onChanged: (value) {
                  setState(() {
                    questiontype = value!;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please choose question type' : null,
                onSaved: (value) {
                  _newSurvey = Survey(
                    id: _newSurvey.id,
                    question: _newSurvey.question,
                    questiontype: value!,
                    ratingcount: _newSurvey.ratingcount,
                    surveytype: _newSurvey.surveytype,
                    surveyfor: _newSurvey.surveyfor,
                  );
                },
              ),
              TextFormField(
                initialValue: _initValues['ratingcount'],
                decoration: const InputDecoration(labelText: 'Rating Count'),
                keyboardType: const TextInputType.numberWithOptions(),
                textInputAction: TextInputAction.done,
                // validator: (value) {
                //   if (value == null || value.trim().isEmpty) {
                //     return 'Please enter ';
                //   }
                //   return null;
                // },
                onSaved: (value) {
                  _newSurvey = Survey(
                    id: _newSurvey.id,
                    question: _newSurvey.question,
                    questiontype: _newSurvey.questiontype,
                    ratingcount: int.parse(value!),
                    surveytype: _newSurvey.surveytype,
                    surveyfor: _newSurvey.surveyfor,
                  );
                },
              ),
              DropdownButtonFormField<dynamic>(
                initialValue:
                    _initValues['surveytype']!.isNotEmpty
                        ? int.parse(_initValues['surveytype'].toString())
                        : null,
                hint: const Text('Survey Type'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Entry Survey')),
                  DropdownMenuItem(value: 2, child: Text('Exit Survey')),
                  DropdownMenuItem(value: 3, child: Text('Both')),
                ],
                onChanged: (value) {
                  setState(() {
                    surveytype = value!;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please choose survey type' : null,
                onSaved: (value) {
                  _newSurvey = Survey(
                    id: _newSurvey.id,
                    question: _newSurvey.question,
                    questiontype: _newSurvey.questiontype,
                    ratingcount: _newSurvey.ratingcount,
                    surveytype: value!,
                    surveyfor: _newSurvey.surveyfor,
                  );
                },
              ),
              DropdownButtonFormField<dynamic>(
                initialValue:
                    _initValues['surveyfor']!.isNotEmpty
                        ? int.parse(_initValues['surveyfor'].toString())
                        : null,
                hint: const Text('Survey Target'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Volunteer')),
                  DropdownMenuItem(value: 2, child: Text('Researcher')),
                ],
                onChanged: (value) {
                  setState(() {
                    surveytarget = value!;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please choose survey target' : null,
                onSaved: (value) {
                  _newSurvey = Survey(
                    id: _newSurvey.id,
                    question: _newSurvey.question,
                    questiontype: _newSurvey.questiontype,
                    ratingcount: _newSurvey.ratingcount,
                    surveytype: _newSurvey.surveytype,
                    surveyfor: value!,
                  );
                },
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: _submit,
                  child: Text(widget.surveyid == 0 ? 'Save' : 'Update'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> pickDate() => showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );
}
