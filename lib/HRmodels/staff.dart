class Staff {
  final int staffId;
  final int userId;
  final String username;
  final String email;
  final int usertype;
  final String firstname;
  final String lastname;
  final String occupation;
  final String phone;
  final int category;
  final String nationality;
  final String religion;
  final int maritalStatus;
  final int gender;
  final String? officePhone;
  final String emergencyName;
  final String emergencyIc;
  final String emergencyRelation;
  final int emergencyGender;
  final String emergencyPhone;
  final String idNum;
  final String dob;
  final String address1;
  final String address2;
  final String city;
  final int postcode;
  final String state;
  final String country;
  final String? filepath;
  final String? filename;

  Staff({
    required this.staffId,
    required this.userId,
    required this.username,
    required this.email,
    required this.usertype,
    required this.firstname,
    required this.lastname,
    required this.occupation,
    required this.phone,
    required this.category,
    required this.nationality,
    required this.religion,
    required this.maritalStatus,
    required this.gender,
    this.officePhone,
    required this.emergencyName,
    required this.emergencyIc,
    required this.emergencyRelation,
    required this.emergencyGender,
    required this.emergencyPhone,
    required this.idNum,
    required this.dob,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postcode,
    required this.state,
    required this.country,
    this.filepath,
    this.filename,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      staffId: json['staff_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      usertype: int.tryParse(json['usertype'].toString()) ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      occupation: json['occupation'] ?? '',
      gender: int.tryParse(json['gender'].toString()) ?? 1,
      phone: json['phone'] ?? '',
      category: int.tryParse(json['category'].toString()) ?? 1,
      nationality: json['nationality'] ?? '',
      religion: json['religion'] ?? '',
      maritalStatus: int.tryParse(json['marital_status'].toString()) ?? 1,
      officePhone: json['office_phone'],
      emergencyName: json['emergency_name'] ?? '',
      emergencyIc: json['emergency_ic'] ?? '',
      emergencyRelation: json['emergency_relation'] ?? '',
      emergencyGender: int.tryParse(json['emergency_gender'].toString()) ?? 1,
      emergencyPhone: json['emergency_phone'] ?? '',
      idNum: json['idnum'] ?? '',
      dob: json['dob'] ?? '',
      address1: json['address1'] ?? '',
      address2: json['address2'] ?? '',
      city: json['city'] ?? '',
      postcode: int.tryParse(json['postcode'].toString()) ?? 0,
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      filepath: json['filepath'],   // ✅ nullable, no default needed
      filename: json['filename'],   // ✅ nullable, no default needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'user_id': userId,
      'username': username,
      'email': email,
      'usertype': usertype,
      'firstname': firstname,
      'lastname': lastname,
      'occupation': occupation,
      'gender': gender,
      'phone': phone,
      'category': category,
      'nationality': nationality,
      'religion': religion,
      'marital_status': maritalStatus,
      'office_phone': officePhone,
      'emergency_name': emergencyName,
      'emergency_ic': emergencyIc,
      'emergency_relation': emergencyRelation,
      'emergency_gender': emergencyGender,
      'emergency_phone': emergencyPhone,
      'idnum': idNum,
      'dob': dob,
      'address1': address1,
      'address2': address2,
      'city': city,
      'postcode': postcode,
      'state': state,
      'country': country,
      // ✅ filepath and filename NOT included in toJson
      // — these are managed by uploadStaffPhoto endpoint only
    };
  }
}