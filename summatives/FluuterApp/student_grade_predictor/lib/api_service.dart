import 'dart:convert';
import 'package:http/http.dart' as http;
 
// ─────────────────────────────────────────────
//  API SERVICE
//  Handles all communication with the FastAPI
//  backend deployed on Render.
// ─────────────────────────────────────────────
 
const String _apiUrl =
    'https://student-performance-api-li3g.onrender.com/predict';
 
class PredictionResult {
  final double grade;
  final String riskLevel;
  final String modelUsed;
 
  const PredictionResult({
    required this.grade,
    required this.riskLevel,
    required this.modelUsed,
  });
}
 
class ApiService {
  /// Sends a POST request to /predict with the student payload.
  /// Returns a [PredictionResult] on success.
  /// Throws a [String] error message on failure.
  static Future<PredictionResult> predict(
      Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PredictionResult(
          grade: (data['predicted_grade'] as num).toDouble(),
          riskLevel: data['risk_level'] as String,
          modelUsed: data['model_used'] as String,
        );
      } else if (response.statusCode == 422) {
        final data   = jsonDecode(response.body);
        final detail = data['detail'];
        String msg   = 'Validation error — ';
        if (detail is List && detail.isNotEmpty) {
          msg += detail
              .map((e) => '${e['loc'].last}: ${e['msg']}')
              .join(', ');
        } else {
          msg += detail.toString();
        }
        throw msg;
      } else {
        throw 'Server error (${response.statusCode}). Please try again.';
      }
    } on String {
      rethrow;
    } on Exception catch (e) {
      throw 'Could not reach the server. Check your connection.\n$e';
    }
  }
}
 