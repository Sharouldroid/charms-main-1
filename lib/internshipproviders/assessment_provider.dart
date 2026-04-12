import 'package:flutter/material.dart';
import 'package:charms/internshipservices/assesstment_service.dart';



class AssessmentProvider with ChangeNotifier {
  Map<String, int> _ratings = {
    'criterion_1': 1,
    'criterion_2': 1,
    'criterion_3': 1,
    'criterion_4': 1,
    'criterion_5': 1,
  };

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, int> get ratings => _ratings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setRating(String criterion, int value) {
    if (_ratings.containsKey(criterion)) {
      _ratings[criterion] = value;
      notifyListeners();
    }
  }

  Future<void> submitAssessment(int internId) async {
    await AssessmentService().submitAssessment(internId, _ratings);
  }

  Future<void> loadAssessmentData(int internId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await AssessmentService().getAssessmentData(internId);
      if (data != null) {
        _ratings = data;
      } else {
        _errorMessage = "No assessment data found";
      }
    } catch (e) {
      _errorMessage = "Failed to load assessment data: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}