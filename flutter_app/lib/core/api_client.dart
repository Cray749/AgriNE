/// AgriSutra NE — API Client
/// ===========================
/// Single source of truth for all HTTP communication with the FastAPI backend.
///
/// Usage (from any screen):
///   final resp = await ApiClient.instance.getRecommendation(request);
///
/// URL configuration guide:
///   Development (Android emulator):  http://10.0.2.2:8000
///   Development (physical device):   http://<YOUR_PC_IP>:8000
///                                    Find your PC IP: run `ipconfig` (Win) or `ifconfig` (Mac/Linux)
///                                    Both phone and PC must be on the same WiFi network.
///   Production (Railway.app):        https://your-app.up.railway.app
///
/// To switch environments, change kBaseUrl below and hot-restart the app.
/// Do NOT commit the production URL to a public git repo unless it is read-only.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiClient {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  // ── Base URL ───────────────────────────────────────────────────────────────
  // Android emulator uses 10.0.2.2 to reach the host machine's localhost.
  // Change this to your Railway URL before building the release APK.
  static const String kBaseUrl = 'http://172.31.34.114:8000';

  // ── Timeout ────────────────────────────────────────────────────────────────
  // 30 seconds is generous. FPE math takes < 1 ms; most time is network.
  // If Railway cold-starts, it can take 5–10 s on the free tier.
  static const Duration kTimeout = Duration(seconds: 30);

  // ── Headers ────────────────────────────────────────────────────────────────
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  // ══════════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ══════════════════════════════════════════════════════════════════════════

  /// Checks if the backend is reachable.
  /// Call this on app startup (from splash screen) if you want to warn the
  /// farmer before they reach the wizard that connectivity is needed.
  ///
  /// Returns true if the server responds to GET /health.
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl/health'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends a fertilizer recommendation request to POST /recommend/.
  ///
  /// Throws an [ApiException] with a farmer-friendly message on failure.
  /// Never throws raw SocketException or FormatException to the caller.
  ///
  /// On success, returns a fully-parsed [RecommendResponse] ready to render.
  Future<RecommendResponse> getRecommendation(RecommendRequest request) async {
    final uri = Uri.parse('$kBaseUrl/recommend/');

    late http.Response response;

    try {
      response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(kTimeout);
    } on SocketException {
      throw ApiException(
        'Could not connect to the server.\n'
        'Please check your internet connection and try again.',
        code: 0,
      );
    } on HttpException {
      throw ApiException(
        'A network error occurred. Please try again.',
        code: 0,
      );
    } on Exception catch (e) {
      // Covers TimeoutException, FormatException, etc.
      throw ApiException(
        'Request failed: ${e.toString()}',
        code: 0,
      );
    }

    // ── Handle HTTP errors ────────────────────────────────────────────────────
    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RecommendResponse.fromJson(json);
      } on FormatException {
        throw ApiException(
          'Received an unexpected response from the server. '
          'Please try again or contact support.',
          code: response.statusCode,
        );
      }
    }

    // ── Parse FastAPI error detail ────────────────────────────────────────────
    String errorMessage;
    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      // FastAPI returns {"detail": "..."} or {"detail": [...]} for validation errors
      final detail = errorJson['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is List) {
        // Pydantic validation error — extract human-readable messages
        errorMessage = detail
            .map((e) => (e as Map<String, dynamic>)['msg'] ?? e.toString())
            .join('\n');
      } else {
        errorMessage = 'Server error (${response.statusCode})';
      }
    } catch (_) {
      errorMessage = 'Server error (${response.statusCode})';
    }

    throw ApiException(errorMessage, code: response.statusCode);
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  EXCEPTION TYPE
// ════════════════════════════════════════════════════════════════════════════

/// Typed exception for all API errors.
///
/// Use [message] directly in UI error dialogs — it is already farmer-friendly.
/// Use [code] for logging and conditional logic (e.g. 422 = validation error).
class ApiException implements Exception {
  final String message;
  final int code;   // HTTP status code, or 0 for network-level failures

  const ApiException(this.message, {required this.code});

  @override
  String toString() => 'ApiException($code): $message';

  /// True if this is a client-side input error (bad data sent to backend).
  bool get isValidationError => code == 422;

  /// True if this is a network failure (no internet, server down).
  bool get isNetworkError => code == 0;
}
