// lib/src/features/health/health_data_point.dart

class CustomHealthDataPoint {
  final String type;
  final double value;
  final DateTime dateFrom; // Start time
  final DateTime dateTo; // End time

  CustomHealthDataPoint({
    required this.type,
    required this.value,
    required this.dateFrom,
    required this.dateTo,
  });

  // Factory method to create CustomHealthDataPoint from a Map (for Android)
  factory CustomHealthDataPoint.fromMap(Map<String, dynamic> map) {
    return CustomHealthDataPoint(
      type: map['type'] ?? 'Unknown',
      value: (map['value'] as num).toDouble(),
      dateFrom: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      dateTo: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
    );
  }

  // Optional: Factory method to create from iOS HealthDataPoint if needed
  // factory CustomHealthDataPoint.fromHealthDataPointIOS(dynamic point) {
  //   // Implement based on HealthDataPointIOS structure
  // }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'dateFrom': dateFrom.millisecondsSinceEpoch,
      'dateTo': dateTo.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomHealthDataPoint &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo;

  @override
  int get hashCode =>
      type.hashCode ^ value.hashCode ^ dateFrom.hashCode ^ dateTo.hashCode;
}
