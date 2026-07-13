import 'dart:convert';

import 'package:charms/models/boat.dart';
import 'package:charms/models/event.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class Boats with ChangeNotifier {
  List<BoatCompany> _companyRecord = [];
  List<Boat> _boatRecord = [];
  List<BoatDriver> _driverRecord = [];
  List<Participant> _participantlist = [];
  List<Participant> _researcherlist = [];

  final List<Event> _assignedEvents = [];
  final List<Event> _unassignedEvents = [];

  List<Event> get assignedEvents => _assignedEvents;
  List<Event> get unassignedEvents => _unassignedEvents;

  List<Event> _eventslist = [];

  List<Event> get eventlist {
    return [..._eventslist];
  }

  List<BoatCompany> get companyRecord {
    return [..._companyRecord];
  }

  List<Boat> get boatRecord {
    return [..._boatRecord];
  }

  List<BoatDriver> get driverRecord {
    return [..._driverRecord];
  }

  BoatCompany findById(int ownerid) {
    return _companyRecord.firstWhere((record) => record.ownerid == ownerid);
  }

  List<Participant> get participantlist {
    return [..._participantlist];
  }

  List<Participant> get researcherlist {
    return [..._researcherlist];
  }

  Future<void> fetchEventGeneral(String hostname, int eventtype) async {
    final url = '${hostname}boat/availableevent/$eventtype';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedEvent = jsonDecode(response.body);
      final List<Event> loadedEvent = [];
      extractedEvent.forEach((eventData) {
        loadedEvent.add(
          Event(
            id: eventData['id'].toString(),
            title: eventData['title'],
            startdate: eventData['startdate'],
            enddate: eventData['enddate'],
            slotvolunteer: eventData['slotvolunteer'],
            slotresearcher: eventData['slotresearcher'],
            price: double.parse(eventData['price'].toString()),
            priceresearcher: double.parse(
              eventData['priceresearcher'].toString(),
            ),
          ),
        );
      });
      _eventslist = loadedEvent;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> createBoatCompany(
    String hostname,
    BoatCompany newBoat,
    int userid,
  ) async {
    final url = '${hostname}boat/create';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'companyname': newBoat.companyname,
        'address': newBoat.address,
        'phone': newBoat.phone,
        'email': newBoat.email,
        'ownerid': userid,
        'registrationno': newBoat.registrationno,
        'boatcount': newBoat.boatcount,
      }),
    );

    // final newBoats = BoatCompany(
    //   id: 0,
    //   companyname: newBoat.companyname,
    //   phone: newBoat.phone,
    //   email: newBoat.email,
    //   address: newBoat.address,
    //   ownerid: userid,
    //   registrationno: newBoat.registrationno,
    //   boatcount: newBoat.boatcount,
    // );
    // _companyRecord.add(newBoats);
    notifyListeners();
  }

  Future<void> updateBoatCompany(
    String hostname,
    BoatCompany newBoat,
    int companyid,
  ) async {
    final url = '${hostname}boat/update';
    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'companyname': newBoat.companyname,
        'address': newBoat.address,
        'phone': newBoat.phone,
        'email': newBoat.email,
        // 'ownerid': userid,
        'registrationno': newBoat.registrationno,
        'boatcount': newBoat.boatcount,
        'id': companyid,
      }),
    );

    // final newBoats = BoatCompany(
    //   id: 0,
    //   companyname: newBoat.companyname,
    //   phone: newBoat.phone,
    //   email: newBoat.email,
    //   address: newBoat.address,
    //   ownerid: userid,
    //   registrationno: newBoat.registrationno,
    //   boatcount: newBoat.boatcount,
    // );
    // _companyRecord.add(newBoats);
    notifyListeners();
  }

  Future<int?> fetchCompanyDatabyUserid(String hostname, int userid) async {
    final url = '${hostname}boat/company/$userid';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load company data');
      }

      final extractedData = jsonDecode(response.body);
      if (extractedData.isEmpty) {
        return null; // No company found
      }

      final List<BoatCompany> loadedRecord = [];
      int? companyId; // Variable to store the company ID

      extractedData.forEach((boatData) {
        final company = BoatCompany(
          id: boatData['id'],
          companyname: boatData['companyname'],
          phone: boatData['phone'],
          email: boatData['email'],
          address: boatData['address'],
          ownerid: boatData['ownerid'],
          registrationno: boatData['registrationno'],
          boatcount: boatData['boatcount'],
          status: boatData['status'],
        );
        loadedRecord.add(company);
        companyId = company.id; // Store the last company ID
      });

      _companyRecord = loadedRecord;
      notifyListeners();
      return companyId; // Return the company ID
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchBoatData(String hostname, int companyid) async {
    final url = '${hostname}boat/boats/$companyid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);
      final List<Boat> loadedRecord = [];
      extractedData.forEach((boatData) {
        loadedRecord.add(
          Boat(
            id: boatData['id'],
            name: boatData['name'],
            capacity: boatData['capacity'],
            companyId: boatData['companyid'],
            status: boatData['status'],
          ),
        );
      });
      _boatRecord = loadedRecord;
      // print(loadedRecord.toString());
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> createBoat(String hostname, Boat newBoat, int companyid) async {
    final url = '${hostname}boat/createboat';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'name': newBoat.name,
        'capacity': newBoat.capacity,
        'companyid': companyid,
      }),
    );

    final newBoats = Boat(
      id: 0,
      name: newBoat.name,
      capacity: newBoat.capacity,
      companyId: newBoat.companyId,
      status: 0,
    );
    _boatRecord.add(newBoats);
    notifyListeners();
  }

  Future<void> updateBoat(
    String hostname,
    Boat newBoat,
    int companyid,
    int boatid,
  ) async {
    final url = '${hostname}boat/updateboat/$boatid';
    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'name': newBoat.name,
        'companyid': companyid,
        'capacity': newBoat.capacity,
        // 'id': boatid,
      }),
    );

    notifyListeners();
  }

  Future<void> fetchBoatDriver(String hostname, int companyid) async {
    final url = '${hostname}boat/drivers/$companyid';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);
      final List<BoatDriver> loadedRecord = [];
      extractedData.forEach((boatData) {
        loadedRecord.add(
          BoatDriver(
            id: boatData['id'],
            fullname: boatData['fullname'],
            ic: boatData['ic'],
            address: boatData['address'],
            phone: boatData['phone'],
            licenseexpiry: boatData['licenseexpiry'],
            companyid: boatData['companyid'],
          ),
        );
      });
      _driverRecord = loadedRecord;
      // print(loadedRecord.toString());
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> createBoatDriver(
    String hostname,
    BoatDriver newDriver,
    int companyid,
  ) async {
    final url = '${hostname}boat/createdriver';

    await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        'fullname': newDriver.fullname,
        'ic': newDriver.ic,
        'address': newDriver.address,
        'phone': newDriver.phone,
        'licenseexpiry': newDriver.licenseexpiry,
        'companyid': companyid,
      }),
    );

    final driver = BoatDriver(
      id: 0,
      fullname: newDriver.fullname,
      ic: newDriver.ic,
      address: newDriver.address,
      phone: newDriver.phone,
      licenseexpiry: newDriver.licenseexpiry,
      companyid: companyid,
    );
    _driverRecord.add(driver);
    notifyListeners();
  }

  Future<void> updateBoatDriver(
    String hostname,
    BoatDriver boatDriver,
    int companyid,
    int driverid,
  ) async {
    final url = '${hostname}boat/updatedriver/$driverid';
    await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      encoding: Encoding.getByName('utf-8'),
      body: jsonEncode({
        // 'id': driverid,
        'fullname': boatDriver.fullname,
        'ic': boatDriver.ic,
        'address': boatDriver.address,
        'phone': boatDriver.phone,
        'licenseexpiry': boatDriver.licenseexpiry,
        'companyid': companyid,
      }),
    );

    notifyListeners();
  }

  Future<void> fetchCompany(String hostname) async {
    final url = '${hostname}boat/';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);
      final List<BoatCompany> loadedRecord = [];
      extractedData.forEach((boatData) {
        loadedRecord.add(
          BoatCompany(
            id: boatData['id'],
            companyname: boatData['companyname'],
            phone: boatData['phone'],
            email: boatData['email'],
            address: boatData['address'],
            ownerid: boatData['ownerid'],
            registrationno: boatData['registrationno'],
            boatcount: boatData['boatcount'],
            status: boatData['status'],
          ),
        );
      });
      _companyRecord = loadedRecord;
      // print(loadedRecord.toString());
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchParticipant(
    String hostname,
    int eventid,
    int volres,
  ) async {
    final url = '${hostname}boat/participant/$eventid/$volres';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);

      // Defensive check
      if (extractedData is List) {
        final List<Participant> loadedData = [];
        for (var participantdata in extractedData) {
          loadedData.add(
            Participant(
              id: participantdata['id'],
              name: participantdata['name'],
              phone: participantdata['phone'],
              email: participantdata['email'],
              pax: participantdata['pax'],
              confirmnum: participantdata['confirmationno'],
              type: participantdata['booktype'],
              date: participantdata['created_at'],
              status: participantdata['status'],
              userid: participantdata['userid'],
              gender: participantdata['gender'] ?? '',
              shirtsize: participantdata['shirtsize'] ?? '',
              diet: participantdata['diet'] ?? '',
              health: participantdata['health'] ?? '',
            ),
          );
        }
        _participantlist = loadedData;
        notifyListeners();
      } else if (extractedData is Map && extractedData.containsKey('message')) {
        throw extractedData['message']; // custom message from backend
      } else {
        throw 'Unexpected response format.';
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchResearcherParticipant(
    String hostname,
    int eventid,
    int volres,
  ) async {
    final url = '${hostname}boat/participant/$eventid/$volres';

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = jsonDecode(response.body);

      // Defensive check
      if (extractedData is List) {
        final List<Participant> loadedData = [];
        for (var participantdata in extractedData) {
          loadedData.add(
            Participant(
              id: participantdata['id'],
              name: participantdata['name'],
              phone: participantdata['phone'],
              email: participantdata['email'],
              pax: participantdata['pax'],
              confirmnum: participantdata['confirmationno'],
              type: participantdata['booktype'],
              date: participantdata['created_at'],
              status: participantdata['status'],
              userid: participantdata['userid'],
                gender: participantdata['gender'] ?? '',
            shirtsize: participantdata['shirtsize'] ?? '',
            diet: participantdata['diet'] ?? '',
            health: participantdata['health'] ?? '',
            
            ),
          );
        }
        _researcherlist = loadedData;
        notifyListeners();
      } else if (extractedData is Map && extractedData.containsKey('message')) {
        throw extractedData['message']; // custom message from backend
      } else {
        throw 'Unexpected response format.';
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> isEventAssigned(String hostname, int eventId) async {
    final response = await http.get(
      Uri.parse('${hostname}boat/checkassigned/$eventId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['assigned'] ?? false;
    }
    return false;
  }

  Future<void> assignTrip(
    String hostname,
    int eventid,
    int companyid,
    int paymentstatus,
    String timedepart, // Changed from DateTime to String
  ) async {
    final url = '${hostname}boat/assignboat';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'eventid': eventid,
        'companyid': companyid,
        'paymentstatus': paymentstatus,
        'timedepart': timedepart, // Already formatted as string
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to assign boat: ${response.body}');
    }

    notifyListeners();
  }

  Future<void> updateReturnTime(
    String hostname,
    int eventId,
    int companyId,
    String returnTime, // Only need return time now
  ) async {
    final url = '${hostname}boat/updatereturn';

    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'eventid': eventId,
        'companyid': companyId,
        'timereturn': returnTime, // Only sending return time
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update return time: ${response.body}');
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> getTripDetails(
    String hostname,
    int eventId,
  ) async {
    final url = '${hostname}boat/tripdetails/$eventId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'id': data['id'] as int,
        'timedepart':
            data['timedepart'] != null
                ? DateTime.parse(data['timedepart'] as String)
                : null,
        'timereturn':
            data['timereturn'] != null
                ? DateTime.parse(data['timereturn'] as String)
                : null,
        'paymentstatus': data['paymentstatus'] as int, // Explicit cast to int
        'filename': data['filename'] as String?,
      };
    }
    throw Exception('Failed to load trip details');
  }

  Future<void> updatePayment(
    String hostname,
    int tripId,
    int? status,
    XFile? proofFile,
  ) async {
    final url = '${hostname}boat/updatepayment';

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields['tripid'] = tripId.toString();
    if (status != null) {
      request.fields['paymentstatus'] = status.toString();
    }

    if (proofFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'paymentproof',
          await proofFile.readAsBytes(),
          filename: 'payment_$tripId.${proofFile.path.split('.').last}',
        ),
      );
    }

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to update payment');
    }
  }
}
