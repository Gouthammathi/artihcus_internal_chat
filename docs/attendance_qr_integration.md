# Attendance QR Code Integration Guide

## Overview

The attendance system uses QR codes that employees display on their phones. The QR code contains employee information and a security signature. Your website scanner should read this QR code and mark attendance.

## QR Code Format

The QR code contains a JSON string with the following structure:

```json
{
  "employeeId": "uuid-of-employee",
  "firstName": "John",
  "lastName": "Doe",
  "role": "employee",
  "department": "Engineering",
  "checkInTime": "2025-01-15T09:30:00.000Z",
  "signature": "hmac-sha256-signature"
}
```

## Security Implementation

### HMAC-SHA256 Signature

To prevent QR code tampering, each QR code includes an HMAC-SHA256 signature.

**Secret Key:** `artihcus_attendance_secret_2025`

**How it works:**
1. The app creates a data string: `employeeId|firstName|lastName|role|department|checkInTime`
2. It generates an HMAC-SHA256 signature using the secret key
3. The signature is included in the QR code

**Website Verification:**
When your website scans the QR code, it should:
1. Extract all fields from the JSON
2. Recreate the data string: `employeeId|firstName|lastName|role|department|checkInTime`
3. Generate the HMAC-SHA256 signature using the same secret key
4. Compare the generated signature with the signature in the QR code
5. If they match, the QR code is valid and hasn't been tampered with

### Example Verification Code (JavaScript)

```javascript
const crypto = require('crypto');

const SECRET_KEY = 'artihcus_attendance_secret_2025';

function verifyQrSignature(qrData) {
  const { employeeId, firstName, lastName, role, department, checkInTime, signature } = qrData;
  
  // Recreate the data string (same format as app)
  const dataToSign = `${employeeId}|${firstName}|${lastName}|${role}|${department || ''}|${checkInTime}`;
  
  // Generate HMAC-SHA256 signature
  const hmac = crypto.createHmac('sha256', SECRET_KEY);
  hmac.update(dataToSign);
  const expectedSignature = hmac.digest('hex');
  
  // Compare signatures
  return expectedSignature === signature;
}

// Usage
const qrData = JSON.parse(scannedQrCodeString);
if (verifyQrSignature(qrData)) {
  // QR code is valid, mark attendance
  markAttendance(qrData);
} else {
  // QR code is invalid or tampered with
  console.error('Invalid QR code signature');
}
```

## QR Code Refresh

- QR codes refresh automatically every **30 seconds**
- Each refresh generates a new timestamp and signature
- This prevents reuse of old QR codes
- The countdown timer is visible to the employee

## Website Integration Steps

1. **Scan the QR Code** using your QR scanner library
2. **Parse the JSON** from the scanned string
3. **Verify the signature** using the method above
4. **Check timestamp** - ensure the checkInTime is recent (within last 60 seconds recommended)
5. **Mark attendance** in your database with the employee information

## Database Integration

When marking attendance, you should store:
- `employeeId` - Unique employee identifier
- `checkInTime` - Timestamp from QR code (ISO 8601 format)
- `scannedAt` - Your server's timestamp when QR was scanned
- `verified` - Whether signature verification passed

## Security Best Practices

1. **Never expose the secret key** in client-side code
2. **Verify signature on the server** - don't trust client-side verification
3. **Check timestamp freshness** - reject QR codes older than 60 seconds
4. **Rate limiting** - prevent abuse by limiting scans per employee per day
5. **Log all scans** - for audit purposes

## Example API Endpoint

```javascript
// POST /api/attendance/scan
app.post('/api/attendance/scan', async (req, res) => {
  const qrData = req.body;
  
  // 1. Verify signature
  if (!verifyQrSignature(qrData)) {
    return res.status(401).json({ error: 'Invalid QR code signature' });
  }
  
  // 2. Check timestamp freshness (within 60 seconds)
  const checkInTime = new Date(qrData.checkInTime);
  const now = new Date();
  const ageInSeconds = (now - checkInTime) / 1000;
  
  if (ageInSeconds > 60) {
    return res.status(400).json({ error: 'QR code expired' });
  }
  
  // 3. Mark attendance
  await markAttendanceInDatabase({
    employeeId: qrData.employeeId,
    checkInTime: checkInTime,
    scannedAt: now,
    employeeName: `${qrData.firstName} ${qrData.lastName}`,
    role: qrData.role,
    department: qrData.department,
  });
  
  res.json({ success: true, message: 'Attendance marked' });
});
```

## Testing

You can test the QR code generation by:
1. Opening the attendance page in the app
2. Scanning the QR code with any QR scanner
3. Verifying the JSON structure matches the format above
4. Testing signature verification with the provided code

## Notes

- The secret key is currently hardcoded. In production, consider:
  - Storing it in environment variables
  - Using a key management service
  - Rotating keys periodically
- QR codes are only generated when the attendance page is open
- Each employee gets a unique QR code based on their login information

