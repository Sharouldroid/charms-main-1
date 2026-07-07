class StaffDocument {
  final int id;
  final int staffId;
  final String documentType; // 'Resume' | 'Identity Card' | 'Bank Statement'
  final String fileName;
  final String filePath;
  final DateTime? submittedAt;
  final DateTime? adminViewedAt;

  StaffDocument({
    required this.id,
    required this.staffId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    this.submittedAt,
    this.adminViewedAt,
  });

  factory StaffDocument.fromJson(Map<String, dynamic> json) {
    return StaffDocument(
      id: int.tryParse(json['id'].toString()) ?? 0,
      staffId: int.tryParse(json['staff_id'].toString()) ?? 0,
      documentType: json['document_type'] ?? '',
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      submittedAt: DateTime.tryParse(json['submitted_at'] ?? ''),
      adminViewedAt: json['admin_viewed_at'] != null
          ? DateTime.tryParse(json['admin_viewed_at'].toString())
          : null,
    );
  }

  StaffDocument copyWith({DateTime? adminViewedAt}) {
    return StaffDocument(
      id: id,
      staffId: staffId,
      documentType: documentType,
      fileName: fileName,
      filePath: filePath,
      submittedAt: submittedAt,
      adminViewedAt: adminViewedAt ?? this.adminViewedAt,
    );
  }
}
