import 'package:flutter/material.dart';
import 'package:charms/internshipservices/assesstment_service.dart';

class AssessmentProvider with ChangeNotifier {
  Map<String, int> _ratings = {};
  Map<String, String> _customCriteriaLabels = {};
  int _nextCustomIndex = 6;

  List<Map<String, dynamic>> _interns = [];
  List<Map<String, dynamic>> _filteredInterns = [];

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, int> get ratings => _ratings;
  Map<String, String> get customCriteriaLabels => Map.unmodifiable(_customCriteriaLabels);
  List<Map<String, dynamic>> get interns => _interns;
  List<Map<String, dynamic>> get filteredInterns => _filteredInterns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Reset ratings to default (used before opening the assess slider screen)
  void resetRatings() {
    _ratings = {
      'criterion_1': 1,
      'criterion_2': 1,
      'criterion_3': 1,
      'criterion_4': 1,
      'criterion_5': 1,
    };
    _customCriteriaLabels = {};
    _nextCustomIndex = 6;
    _errorMessage = null;
    notifyListeners();
  }

  void setRating(String criterion, int value) {
    if (_ratings.containsKey(criterion)) {
      _ratings[criterion] = value;
      notifyListeners();
    }
  }

  void addCustomCriterion(String label) {
    final key = 'criterion_$_nextCustomIndex';
    _nextCustomIndex++;
    _ratings[key] = 1;
    _customCriteriaLabels[key] = label;
    notifyListeners();
  }

  void removeCustomCriterion(String key) {
    _ratings.remove(key);
    _customCriteriaLabels.remove(key);
    notifyListeners();
  }

  void searchInterns(String query) {
    if (query.isEmpty) {
      _filteredInterns = List.from(_interns);
    } else {
      final q = query.toLowerCase();
      _filteredInterns = _interns.where((intern) {
        final name = (intern['name'] ?? '').toString().toLowerCase();
        final email = (intern['email'] ?? '').toString().toLowerCase();
        final university =
            (intern['university'] ?? '').toString().toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            university.contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> fetchInterns() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await AssessmentService().getInterns();
      _interns = data;
      _filteredInterns = List.from(_interns);
    } catch (e) {
      _errorMessage = 'Failed to load interns: $e';
    } finally {
      _isLoading = false;
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
        _errorMessage = null;
      } else {
        _errorMessage = 'No assessment data found';
        _ratings = {}; // ← clear so 0.0 score card is hidden
      }
    } catch (e) {
      _errorMessage = 'Failed to load assessment data: $e';
      _ratings = {}; // ← clear on error too
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}