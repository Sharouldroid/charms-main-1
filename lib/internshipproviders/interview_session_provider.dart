import 'package:flutter/material.dart';
import 'package:charms/internshipmodels/interview_session.dart';
import 'package:charms/internshipservices/interview_session_service.dart';
import 'package:charms/main.dart';

class InterviewSessionProvider with ChangeNotifier {
  List<InterviewSession> _availableSessions = [];
  List<InterviewSession> _allSessions = [];
  InterviewSession? _mySession;

  final InterviewSessionService _service =
      InterviewSessionService(baseUrl: AppConfig.hostname);

  List<InterviewSession> get availableSessions => _availableSessions;
  List<InterviewSession> get allSessions => _allSessions;
  InterviewSession? get mySession => _mySession;

  Future<void> loadAvailableSessions() async {
    _availableSessions = await _service.fetchAvailableSessions();
    notifyListeners();
  }

  Future<void> loadAllSessions() async {
    _allSessions = await _service.fetchAllSessions();
    notifyListeners();
  }

  Future<void> loadMySession(int userId) async {
    _mySession = await _service.fetchMySession(userId);
    notifyListeners();
  }

  Future<void> createSession(
      DateTime date, String startTime, String endTime) async {
    await _service.createSession(date, startTime, endTime);
    await loadAllSessions();
  }

  Future<void> bookSession(int sessionId, int userId) async {
    await _service.bookSession(sessionId, userId);
    await loadMySession(userId);
    await loadAvailableSessions();
  }

  Future<void> updateMeetingLink(int sessionId, String meetingLink) async {
    await _service.updateMeetingLink(sessionId, meetingLink);
    await loadAllSessions();
  }

  Future<void> completeSession(int sessionId) async {
    await _service.completeSession(sessionId);
    await loadAllSessions();
  }

  Future<void> cancelBooking(int sessionId) async {
    await _service.cancelBooking(sessionId);
    await loadAllSessions();
  }

  Future<void> deleteSession(int sessionId) async {
    await _service.deleteSession(sessionId);
    _allSessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }
}
