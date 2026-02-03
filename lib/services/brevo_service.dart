import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BrevoService {
  // Brevo (Sendinblue) API Key V3
  // ⚠️ SECURITY WARNING: In production, it is recommended to move this to a backend service.
  static const String _apiKey = 'your api key here';

  // Brevo V3 SMTP Endpoint
  static const String _baseUrl = 'https://api.brevo.com/v3/smtp/email';

  // Sender details - IMPORTANT: This email MUST be verified in your Brevo account (Senders & IPs)
  static const String _senderName = 'Ledger Book Support';
  static const String _senderEmail = 'ltztop24poi0@gmail.com';

  /// Generic method to send an email using Brevo API
  Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
    String? toName,
  }) async {
    try {
      final url = Uri.parse(_baseUrl);

      final body = {
        "sender": {"name": _senderName, "email": _senderEmail},
        "to": [
          {"email": toEmail, "name": toName ?? toEmail.split('@')[0]},
        ],
        "subject": subject,
        "htmlContent": htmlContent,
      };

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'api-key': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('📧 Email sent successfully to $toEmail');
        return true;
      } else {
        debugPrint('❌ Failed to send email. Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
      return false;
    }
  }

  /// 1. Welcome Alert Integration
  Future<void> sendWelcomeEmail(String email, String name) async {
    const String subject = 'Welcome to Ledger App! 🚀';

    // Professional HTML Template for Welcome
    final String htmlContent =
        '''
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
          <h2 style="color: #4CAF50; text-align: center;">Welcome to Ledger App!</h2>
          <p>Hi <strong>$name</strong>,</p>
          <p>We are thrilled to have you on board! Thank you for choosing Ledger App to manage your finances effectively.</p>
          <p>Here is what you can do next:</p>
          <ul>
            <li>📝 Add your first transaction</li>
            <li>📊 Check your dashboard analytics</li>
            <li>⚙️ Customize your categories</li>
          </ul>
          <p>If you have any questions, feel free to reply to this email.</p>
          <br>
          <p>Best Regards,</p>
          <p><strong>The Ledger App Team</strong></p>
        </div>
      </body>
      </html>
    ''';

    await sendEmail(
      toEmail: email,
      toName: name,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// 2. Email Verification (OTP Based)
  /// Use this if you want to verify emails manually instead of using Firebase Links
  Future<bool> sendVerificationOtp(String email, String otpCode) async {
    const String subject = 'Verify your Ledger App Email';

    final String htmlContent =
        '''
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif; text-align: center;">
        <div style="padding: 20px;">
          <h2>Email Verification</h2>
          <p>Please use the code below to verify your email address.</p>
          <h1 style="letter-spacing: 5px; background-color: #f4f4f4; padding: 10px; display: inline-block; border-radius: 5px;">$otpCode</h1>
          <p>This code will expire in 10 minutes.</p>
        </div>
      </body>
      </html>
    ''';

    return await sendEmail(
      toEmail: email,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// 3. Forgot Password (OTP Based or Link)
  Future<void> sendPasswordResetAlert(String email, String resetLink) async {
    const String subject = 'Reset Your Password';

    final String htmlContent =
        '''
      <!DOCTYPE html>
      <html>
      <body>
        <h3>Password Reset Request</h3>
        <p>We received a request to reset your password. Click the link below to proceed:</p>
        <p><a href="$resetLink" style="background-color: #007BFF; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Reset Password</a></p>
        <p>If you didn't request this, purely ignore this email.</p>
      </body>
      </html>
    ''';

    await sendEmail(toEmail: email, subject: subject, htmlContent: htmlContent);
  }

  /// 4. General Alert / Notification
  Future<void> sendAlert(String email, String title, String message) async {
    await sendEmail(
      toEmail: email,
      subject: title,
      htmlContent: '<p>$message</p>',
    );
  }
}
