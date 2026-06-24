class Register {
  // Personal Information
  final int? userId;
  final String firstName;
  final String lastName;
  final String dateOfBirth; // Stored as a string in 'yyyy-MM-dd' format
  final String icNumber; // No. Kad Pengenalan (e.g. 030405-11-0417)
  final int age;
  final String gender;

  // Institution Information
  final String levelOfStudy;
  final String institutionName;
  final String programme;
  final String course;
  final String faculty;
  final String branch;

  // Address Information
  final String streetAddress1;
  final String? streetAddress2; // Optional
  final String city;
  final String state;
  final String postalCode;
  final String country;

  // Contact Information
  final String areaCode;
  final String phoneNumber;
  final String email;
  final String? password;

  // Schedule Information
  final int scheduleId; // Add scheduleId

  Register({
    // Personal Information
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.icNumber,
    required this.age,
    required this.gender,
    this.userId,

    // Institution Information
    required this.levelOfStudy,
    required this.institutionName,
    required this.programme,
    required this.course,
    required this.faculty,
    required this.branch,

    // Address Information
    required this.streetAddress1,
    this.streetAddress2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,

    // Contact Information
    required this.areaCode,
    required this.phoneNumber,
    required this.email,
    this.password,

    // Schedule Information
    required this.scheduleId, // Add scheduleId
  });

  factory Register.fromJson(Map<String, dynamic> json) {
    return Register(
      // Personal Information
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'],
      icNumber: json['ic_number'] ?? '',
      age: json['age'],
      gender: json['gender'],

      // Institution Information
      levelOfStudy: json['level_of_study'],
      institutionName: json['institution_name'],
      programme: json['programme'],
      course: json['course'],
      faculty: json['faculty'] ?? '',
      branch: json['branch'] ?? '',

      // Address Information
      streetAddress1: json['street_address_1'],
      streetAddress2: json['street_address_2'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'],

      // Contact Information
      areaCode: json['area_code'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      //password: json['password'],

      // Schedule Information
      scheduleId: json['schedule_id'], // Add scheduleId
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      // Personal Information
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'ic_number': icNumber,
      'age': age,
      'gender': gender,

      // Institution Information
      'level_of_study': levelOfStudy,
      'institution_name': institutionName,
      'programme': programme,
      'course': course,
      'faculty': faculty,
      'branch': branch,

      // Address Information
      'street_address_1': streetAddress1,
      'street_address_2': streetAddress2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,

      // Contact Information
      'area_code': areaCode,
      'phone_number': phoneNumber,
      'email': email,
      //'password': password,

      // Schedule Information
      'schedule_id': scheduleId, // Add scheduleId
    };

    // ✅ Only include password if it's provided
    if (password != null && password!.isNotEmpty) {
      json['password'] = password;
    }

    return json;
  }
}