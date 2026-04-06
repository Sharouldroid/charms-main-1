import 'dart:convert';
import 'dart:io';

import 'package:charms/models/survey.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';

class Surveys with ChangeNotifier {
  List<Survey> _surveylist = [];
  List<SurveyAnswer> _entryanswer = [];
  List<SurveyAnswer> _exitanswer = [];
  List<Map<String, dynamic>> _vollist = [];
  List<Map<String, dynamic>> _reslist = [];

  List<Map<String, dynamic>> get vollist {
    return [..._vollist];
  }

  List<Map<String, dynamic>> get reslist {
    return [..._reslist];
  }

  // List<SurveyResponse> _indemAnswer = [];

  List<Survey> get surveylist {
    return [..._surveylist];
  }

  List<SurveyAnswer> get entryanswer {
    return [..._entryanswer];
  }

  List<SurveyAnswer> get exitanswer {
    return [..._exitanswer];
  }

  Future<void> createSurvey(String hostname, Survey survey, int userid) async {
    final url = '${hostname}survey/create';

    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'question': survey.question,
          'questiontype': survey.questiontype,
          'ratingcount': survey.ratingcount,
          'surveytype': survey.surveytype,
          'surveyfor': survey.surveyfor,
          'createdby': userid,
        }),
      );

      final newSurvey = Survey(
        id: 0,
        question: survey.question,
        questiontype: survey.questiontype,
        ratingcount: survey.ratingcount,
        surveytype: survey.surveytype,
        surveyfor: survey.surveyfor,
      );
      _surveylist.add(newSurvey);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateSurvey(
    String hostname,
    Survey survey,
    int userid,
    int id,
  ) async {
    final url = '${hostname}survey/update/$id';
    final surveyIndex = _surveylist.indexWhere((indem) => indem.id == id);

    try {
      await http.put(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'id': id,
          'question': survey.question,
          'questiontype': survey.questiontype,
          'ratingcount': survey.ratingcount,
          'surveytype': survey.surveytype,
          'surveyfor': survey.surveyfor,
        }),
      );

      _surveylist[surveyIndex] = survey;

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchSurveybyType(String hostname, int type, int status) async {
    final url = '${hostname}survey/$type/$status';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<Survey> loadedsurvey = [];
      extactedData.forEach((surveyData) {
        loadedsurvey.add(
          Survey(
            id: surveyData['id'],
            question: surveyData['question'],
            questiontype: surveyData['questiontype'],
            ratingcount: surveyData['ratingcount'],
            surveytype: surveyData['surveytype'],
            surveyfor: surveyData['surveyfor'],
          ),
        );
      });
      _surveylist = loadedsurvey;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> answerEntrySurvey(
    String hostname,
    Map<int, dynamic> survey,
    int userid,
    int eventid,
    int confirmnum,
  ) async {
    final url = '${hostname}survey/answerentry';

    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'userid': userid,
          'eventid': eventid,
          'confirmnum': confirmnum,
          'surveyanswer': survey.toString(),
        }),
      );

      showSimpleNotification(
        const Text(
          'Entry Survey Completed!',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        duration: const Duration(seconds: 2),
        background: Colors.green,
      );

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> answerExitSurvey(
    String hostname,
    Map<int, dynamic> survey,
    int userid,
    int eventid,
    int confirmnum,
  ) async {
    final url = '${hostname}survey/answerexit';

    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'userid': userid,
          'eventid': eventid,
          'confirmnum': confirmnum,
          'surveyanswer': survey.toString(),
        }),
      );

      showSimpleNotification(
        const Text(
          'Exit Survey Completed!',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        duration: const Duration(seconds: 2),
        background: Colors.green,
      );

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> fetchEntrySurvey(
    String hostname,
    int userid,
    int confirmnum,
  ) async {
    final url = '${hostname}survey/entry/$userid/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<SurveyAnswer> loadedsurvey = [];
      extactedData.forEach((surveyData) {
        loadedsurvey.add(
          SurveyAnswer(
            id: surveyData['id'],
            userid: surveyData['userid'],
            eventid: surveyData['eventid'],
            surveyanswer: surveyData['surveyanswer'].toString(),
          ),
        );
      });
      _entryanswer = loadedsurvey;
      notifyListeners();

      if (_entryanswer.isEmpty) {
        return false;
      } else {
        return true;
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> fetchExitSurvey(
    String hostname,
    int userid,
    int confirmnum,
  ) async {
    final url = '${hostname}survey/exit/$userid/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<SurveyAnswer> loadedsurvey = [];
      extactedData.forEach((surveyData) {
        loadedsurvey.add(
          SurveyAnswer(
            id: surveyData['id'],
            userid: surveyData['userid'],
            eventid: surveyData['eventid'],
            surveyanswer: surveyData['surveyanswer'].toString(),
          ),
        );
      });
      _exitanswer = loadedsurvey;
      notifyListeners();

      if (_exitanswer.isEmpty) {
        return false;
      } else {
        return true;
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchAllSurveys(String hostname) async {
    final url = '${hostname}survey/all';

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);
      final List<Survey> loadedsurvey = [];
      extactedData.forEach((surveyData) {
        loadedsurvey.add(
          Survey(
            id: surveyData['id'],
            question: surveyData['question'],
            questiontype: surveyData['questiontype'],
            ratingcount: surveyData['ratingcount'],
            surveytype: surveyData['surveytype'],
            surveyfor: surveyData['surveyfor'],
            status: surveyData['status'],
          ),
        );
      });
      _surveylist = loadedsurvey;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchBookedbyId(String hostname, int eventid) async {
    final url = '${hostname}survey/event/$eventid';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the API returned success
        if (responseData['success'] == true) {
          final extractedData = responseData['data'] as List;
          List<Map<String, dynamic>> loadedEvents = [];

          for (var eventData in extractedData) {
            loadedEvents.add({
              'id': eventData['id']?.toString() ?? '0',
              'eventid': eventData['eventid']?.toString() ?? '0',
              'userid': eventData['userid']?.toString() ?? '0',
              'name': '${eventData['firstname']} ${eventData['lastname']}',
              'title': eventData['title'] ?? 'Untitled Event',
              'startdate': eventData['startdate'] ?? '',
              'enddate': eventData['enddate'] ?? '',
              'slotvolunteer': eventData['slotvolunteer'] ?? 0,
              'slotresearcher': eventData['slotresearcher'] ?? 0,
              'datebook': eventData['created_at'] ?? '',
              'confirmnum': eventData['confirmationno']?.toString() ?? '0',
              'booktype': eventData['booktype'] ?? 0,
              'price':
                  double.tryParse(eventData['amount']?.toString() ?? '0') ??
                  0.0,
              'priceresearcher':
                  double.tryParse(
                    eventData['priceresearcher']?.toString() ?? '0',
                  ) ??
                  0.0,
              'total':
                  double.tryParse(eventData['amount']?.toString() ?? '0') ??
                  0.0,
              'status': eventData['status'] ?? 0,
              'cancelreason': eventData['cancelreason'] ?? '',
            });
          }

          _vollist = loadedEvents;
          notifyListeners();
        } else {
          throw Exception('Failed to load data: ${responseData['message']}');
        }
      } else {
        throw Exception(
          'Failed to load data with status: ${response.statusCode}',
        );
      }
    } catch (error) {
      // You might want to handle different error types differently
      if (error is SocketException) {
        throw Exception('No Internet connection');
      } else if (error is FormatException) {
        throw Exception('Bad response format');
      } else {
        rethrow;
      }
    }
  }

  Future<void> fetchBookedResbyId(String hostname, int eventid) async {
    final url = '${hostname}survey/eventres/$eventid';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the API returned success
        if (responseData['success'] == true) {
          final extractedData = responseData['data'] as List;
          List<Map<String, dynamic>> loadedEvents = [];

          for (var eventData in extractedData) {
            loadedEvents.add({
              'id': eventData['id']?.toString() ?? '0',
              'eventid': eventData['eventid']?.toString() ?? '0',
              'userid': eventData['userid']?.toString() ?? '0',
              'name': '${eventData['firstname']} ${eventData['lastname']}',
              'title': eventData['title'] ?? 'Untitled Event',
              'startdate': eventData['startdate'] ?? '',
              'enddate': eventData['enddate'] ?? '',
              'slotvolunteer': eventData['slotvolunteer'] ?? 0,
              'slotresearcher': eventData['slotresearcher'] ?? 0,
              'datebook': eventData['created_at'] ?? '',
              'confirmnum': eventData['confirmationno']?.toString() ?? '0',
              'booktype': eventData['booktype'] ?? 0,
              'price':
                  double.tryParse(eventData['amount']?.toString() ?? '0') ??
                  0.0,
              'priceresearcher':
                  double.tryParse(
                    eventData['priceresearcher']?.toString() ?? '0',
                  ) ??
                  0.0,
              'total':
                  double.tryParse(eventData['amount']?.toString() ?? '0') ??
                  0.0,
              'status': eventData['status'] ?? 0,
              'cancelreason': eventData['cancelreason'] ?? '',
            });
          }

          _reslist = loadedEvents;
          notifyListeners();
        } else {
          throw Exception('Failed to load data: ${responseData['message']}');
        }
      } else {
        throw Exception(
          'Failed to load data with status: ${response.statusCode}',
        );
      }
    } catch (error) {
      // You might want to handle different error types differently
      if (error is SocketException) {
        throw Exception('No Internet connection');
      } else if (error is FormatException) {
        throw Exception('Bad response format');
      } else {
        rethrow;
      }
    }
  }

  Future<bool> fetchEntrySurveywithQuestion(
    String hostname,
    int userid,
    int confirmnum,
  ) async {
    final url = '${hostname}survey/fetchqaentry/$userid/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);

      if (extractedData['survey'] == null || extractedData['answers'] == null) {
        throw Exception('Invalid response format');
      }

      // Extract the survey metadata (survey details)
      final survey = extractedData['survey'];
      final List<SurveyAnswer> loadedSurveyAnswers = [];

      // Process the answers (iterate over the answers list)
      for (var answerData in extractedData['answers']) {
        loadedSurveyAnswers.add(
          SurveyAnswer(
            id: survey['id'], // Get the survey ID
            userid: survey['userid'], // Get the user ID
            eventid: survey['eventid'], // Get the event ID
            surveyanswer: answerData['answer'].toString(), // Store the answer
            questionText:
                answerData['question_text'], // Store the question text
          ),
        );
      }

      _entryanswer = loadedSurveyAnswers;
      notifyListeners();

      return _entryanswer.isNotEmpty;
    } catch (error) {
      print('Error fetching exit survey: $error');
      rethrow;
    }
  }

  Future<bool> fetchExitSurveywithQuestion(
    String hostname,
    int userid,
    int confirmnum,
  ) async {
    final url = '${hostname}survey/fetchqaexit/$userid/$confirmnum';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);

      if (extractedData['survey'] == null || extractedData['answers'] == null) {
        throw Exception('Invalid response format');
      }

      // Extract the survey metadata (survey details)
      final survey = extractedData['survey'];
      final List<SurveyAnswer> loadedSurveyAnswers = [];

      // Process the answers (iterate over the answers list)
      for (var answerData in extractedData['answers']) {
        loadedSurveyAnswers.add(
          SurveyAnswer(
            id: survey['id'], // Get the survey ID
            userid: survey['userid'], // Get the user ID
            eventid: survey['eventid'], // Get the event ID
            surveyanswer: answerData['answer'].toString(), // Store the answer
            questionText:
                answerData['question_text'], // Store the question text
          ),
        );
      }

      _exitanswer = loadedSurveyAnswers;
      notifyListeners();

      return _exitanswer.isNotEmpty;
    } catch (error) {
      print('Error fetching exit survey: $error');
      rethrow;
    }
  }
}
