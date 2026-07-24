class ScanResultModel {
  final String id;
  final String userId;
  final String? scanImageUrl;
  final Map<String, dynamic>? scanResult;
  final double? confidence;
  final String scanType;
  final DateTime? createdAt;

  const ScanResultModel({
    required this.id,
    required this.userId,
    this.scanImageUrl,
    this.scanResult,
    this.confidence,
    this.scanType = 'YOLOv8',
    this.createdAt,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scanImageUrl: json['scan_image_url'] as String?,
      scanResult: json['scan_result'] as Map<String, dynamic>?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      scanType: json['scan_type'] as String? ?? 'YOLOv8',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (scanImageUrl != null) 'scan_image_url': scanImageUrl,
      if (scanResult != null) 'scan_result': scanResult,
      if (confidence != null) 'confidence': confidence,
      'scan_type': scanType,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}