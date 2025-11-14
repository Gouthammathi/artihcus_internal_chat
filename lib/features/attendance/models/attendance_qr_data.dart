import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Model for attendance QR code data
/// This is what gets encoded in the QR code
class AttendanceQrData {
  const AttendanceQrData({
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.department,
    required this.checkInTime,
    required this.signature,
  });

  final String employeeId;
  final String firstName;
  final String lastName;
  final String role;
  final String? department;
  final String checkInTime; // ISO 8601 format
  final String signature; // HMAC signature for security

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'department': department,
        'checkInTime': checkInTime,
        'signature': signature,
      };

  /// Convert to JSON string (for QR code)
  String toJsonString() => jsonEncode(toJson());

  /// Create from JSON
  factory AttendanceQrData.fromJson(Map<String, dynamic> json) {
    return AttendanceQrData(
      employeeId: json['employeeId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      department: json['department'] as String?,
      checkInTime: json['checkInTime'] as String,
      signature: json['signature'] as String,
    );
  }

  /// Verify the signature
  /// The website should use the same secret key to verify
  bool verifySignature(String secretKey) {
    final dataToSign = '$employeeId|$firstName|$lastName|$role|${department ?? ''}|$checkInTime';
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(dataToSign));
    return digest.toString() == signature;
  }
}

