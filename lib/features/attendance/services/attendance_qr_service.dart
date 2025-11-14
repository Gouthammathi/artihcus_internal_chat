import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../data/models/employee.dart';
import '../models/attendance_qr_data.dart';

/// Service to generate secure attendance QR codes
class AttendanceQrService {
  // Secret key for HMAC signature
  // In production, this should be stored securely (e.g., in environment variables)
  // Both the app and website need to use the same secret key
  static const String _secretKey = 'artihcus_attendance_secret_2025';

  /// Generate QR code data for an employee
  /// 
  /// This creates a JSON object with employee info and a security signature.
  /// The signature prevents tampering - if someone tries to modify the QR data,
  /// the signature won't match and the website will reject it.
  static AttendanceQrData generateQrData(Employee employee) {
    final checkInTime = DateTime.now().toUtc().toIso8601String();

    // Create data string for signing (without signature)
    final dataToSign = '${employee.id}|${employee.firstName}|${employee.lastName}|${employee.role.name}|${employee.department ?? ''}|$checkInTime';

    // Generate HMAC-SHA256 signature
    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmac.convert(utf8.encode(dataToSign));
    final signature = digest.toString();

    return AttendanceQrData(
      employeeId: employee.id,
      firstName: employee.firstName,
      lastName: employee.lastName,
      role: employee.role.name,
      department: employee.department,
      checkInTime: checkInTime,
      signature: signature,
    );
  }

  /// Get the secret key (for website integration)
  /// In production, this should be shared securely between app and website
  static String get secretKey => _secretKey;
}

