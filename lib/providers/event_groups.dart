import 'dart:async';
import 'dart:convert';
import 'package:charms/models/event.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EventGroups with ChangeNotifier {
  List<RSSMember> _rssmemberlist = [];

  List<RSSMember> get rssmemberlist {
    return [..._rssmemberlist];
  }

  Future<void> fetchRSSGroup(String hostname, int specialid) async {
    final url = '${hostname}rss/group/$specialid';

    try {
      final response = await http.get(Uri.parse(url));
      final responseData = jsonDecode(response.body);
      final List<RSSMember> loadedData = [];
      responseData.forEach((rssdata) {
        loadedData.add(
          RSSMember(
            id: rssdata['id'] ?? 0,
            name: rssdata['name'] ?? '',
            idnum: rssdata['idnum'] ?? '',
            email: rssdata['email'] ?? '',
          ),
        );
      });
      _rssmemberlist = loadedData;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> fetchMemberIndemnities(
    String hostname,
    String email,
    int confirmnum,
  ) async {
    final url = '${hostname}researcher/$email/$confirmnum';
    // print('sapa sini ke dok');

    try {
      final response = await http.get(Uri.parse(url));
      final extactedData = jsonDecode(response.body);

      // print(extactedData[0]['indemnities']);

      notifyListeners();
      if (extactedData[0]['indemnities'] != null) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      rethrow;
    }
  }
}
