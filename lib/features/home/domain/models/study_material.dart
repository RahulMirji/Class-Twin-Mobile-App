/// Study material (notes, docs) model
class StudyMaterial {
  final String id;
  final String teacherId;
  final String title;
  final String subject;
  final String? topic;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final int? pageCount;
  final String? storageUrl;
  final String status;
  final DateTime createdAt;

  const StudyMaterial({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.subject,
    this.topic,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.pageCount,
    this.storageUrl,
    this.status = 'published',
    required this.createdAt,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String?,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int?,
      pageCount: json['page_count'] as int?,
      storageUrl: json['storage_url'] as String?,
      status: json['status'] as String? ?? 'published',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get fileExtension => fileName.split('.').last.toLowerCase();
}
