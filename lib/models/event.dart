/// Example event class.
class Event2 {
  final String title;
  final DateTime startdate;
  final DateTime enddate;
  final int id;

  const Event2({
    required this.title,
    required this.startdate,
    required this.enddate,
    required this.id,
  });
}

class Event {
  final String id;
  final String title;
  final String startdate;
  final String enddate;
  final int slotvolunteer;
  final int slotresearcher;
  final int eventtype;
  final double price;
  final double priceresearcher;
  final int? createdby;
  final int? approve1;
  final int? approve2;
  final int status;
  final String? datebook;
  int confirmnum;
  int booktype;
  final int pax;
  final double total;
  final String cancelreason;
  final int applicantid;

  Event({
    required this.id,
    required this.title,
    required this.startdate,
    required this.enddate,
    required this.slotvolunteer,
    required this.slotresearcher,
    this.eventtype = 1,
    required this.price,
    required this.priceresearcher,
    this.createdby,
    this.approve1,
    this.approve2,
    this.status = 0,
    this.datebook,
    this.confirmnum = 0,
    this.booktype = 0,
    this.pax = 0,
    this.total = 0,
    this.cancelreason = '',
    this.applicantid = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      title: json['title'] ?? 'Untitled',
      startdate: json['startdate'] ?? '',
      enddate: json['enddate'] ?? '',
      slotvolunteer: json['slotvolunteer'] ?? 0,
      slotresearcher: json['slotresearcher'] ?? 0,
      datebook: json['datebook'] ?? '',
      confirmnum: json['confirmnum'] ?? 0,
      booktype: json['booktype'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      priceresearcher: json['priceresearcher'] ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 0,
      cancelreason: json['cancelreason']?.toString() ?? 'No reason provided',
    );
  }
}

class Participant {
  final int id;
  final String name;
  final String phone;
  final String email;
  final int pax;
  final int confirmnum;
  final int type;
  final String date;
  final int status;
  final double total;
  final int userid;
  final int needboat;
  final String? paymentproof;

  // --- NEW FIELDS ---
  final int gender; // Kept as String to satisfy UI/PDF
  final String shirtsize;
  final String diet;
  final String health;

  const Participant({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.pax,
    required this.confirmnum,
    required this.type,
    required this.date,
    required this.status,
    this.total = 0,
    required this.userid,
    this.needboat = 1,
    this.paymentproof,
    required this.gender,
    required this.shirtsize,
    required this.diet,
    required this.health,
  });

factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] ?? json['booking_id'] ?? 0,
      
      // ✅ SAFETY METHOD: Convert EVERYTHING to String using .toString()
      // This prevents "int is not a subtype of String" errors completely.
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '', 
      email: json['email']?.toString() ?? '',
      
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      pax: int.tryParse(json['pax']?.toString() ?? '0') ?? 0,
      confirmnum: int.tryParse(json['confirmationno']?.toString() ?? '0') ?? 0,
      type: int.tryParse(json['booktype']?.toString() ?? '0') ?? 0,
      userid: int.tryParse(json['userid']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      
      date: json['created_at']?.toString() ?? '', 
      paymentproof: json['paymentproof'],

      // ✅ Gender is now parsed as int. We format it in the UI.
      gender: int.tryParse(json['gender']?.toString() ?? '0') ?? 0,
      shirtsize: json['shirtsize']?.toString() ?? '-',
      diet: (json['diet_restriction'] ?? json['diet'])?.toString() ?? 'None',
      health: (json['health_condition'] ?? json['health'])?.toString() ?? 'None',
    );
  }
}

// ... Rest of your helper classes (SpecialEvent, RSSMember, etc.) remain unchanged below ...
int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

class SpecialEvent {
  final int id;
  final int pax;
  final String startdate;
  final String enddate;
  final int needboat;
  final int status;
  final int amount;
  final int processedby;
  final String rejectreason;
  final int applicantid;
  final String picemail;

  const SpecialEvent({
    required this.id,
    required this.pax,
    required this.startdate,
    required this.enddate,
    this.needboat = 0,
    this.status = 0,
    this.amount = 0,
    this.processedby = 0,
    this.rejectreason = '',
    this.applicantid = 0,
    this.picemail = '',
  });
}

class RSSMember {
  final int id;
  final String name;
  final String idnum;
  final String email;

  const RSSMember({
    required this.id,
    required this.name,
    required this.idnum,
    required this.email,
  });
}

class RSSAffiliation {
  final int id;
  final String title;
  final String department;
  final String institution;
  final String location;
  final String filename;

  const RSSAffiliation({
    required this.id,
    required this.title,
    required this.department,
    required this.institution,
    required this.location,
    required this.filename,
  });
}

class KPPData {
  final int id;
  final int kppid;
  final String filename;

  const KPPData({
    required this.id,
    required this.kppid,
    required this.filename,
  });
}

class DayTrip {
  final int id;
  final int userid;
  final int companyid;
  final int pax;
  final String selecteddate;
  final String selectedtime;
  final int amount;
  final int status;
  final String rejectreason;
  final int processedby;
  final String company;

  const DayTrip({
    required this.id,
    required this.userid,
    required this.companyid,
    required this.pax,
    required this.selecteddate,
    required this.selectedtime,
    required this.amount,
    required this.status,
    this.rejectreason = '',
    this.processedby = 0,
    this.company = '',
  });
}