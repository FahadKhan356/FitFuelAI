class FoodScanResultEntity {
  final String id;
  final String userId;
  final String? scanImageUrl;
  final Map<String, dynamic>? scanResult;
  final double? confidence;
  final String scanType;
  final DateTime? createdAt;

  const FoodScanResultEntity({
    required this.id,
    required this.userId,
    this.scanImageUrl,
    this.scanResult,
    this.confidence,
    this.scanType = 'YOLOv8',
    this.createdAt,
  });
}