import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.qrData,
    required this.timestamp,
  });

  final String id;
  final String qrData;
  final DateTime timestamp;

  String get formattedDate => DateFormat('EEEE, dd MMM yyyy').format(timestamp);

  String get formattedTime => DateFormat('hh:mm a').format(timestamp);

  Map<String, dynamic> toJson() => {
        'id': id,
        'qrData': qrData,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      qrData: json['qrData'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  bool isSameDay(DateTime other) =>
      timestamp.year == other.year &&
      timestamp.month == other.month &&
      timestamp.day == other.day;

  @override
  List<Object?> get props => [id, qrData, timestamp];
}




