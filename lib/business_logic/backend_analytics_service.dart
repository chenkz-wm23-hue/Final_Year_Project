import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendAnalyticsService {
  BackendAnalyticsService({
    required this.client,
    this.httpClient,
    this.timeout = const Duration(seconds: 45),
  });

  final SupabaseClient client;
  final http.Client? httpClient;
  final Duration timeout;
  static const baseUrl = 'https://fyp-financial-analytics-backend.onrender.com';

  Future<Map<String, dynamic>> getMyAnalytics() => _get('/api/v1/my-analytics');
  Future<Map<String, dynamic>> getMyPredictiveAnalytics() =>
      _get('/api/v1/my-predictive-analytics');

  Future<Map<String, dynamic>> _get(String path) async {
    final token = client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const AnalyticsException(
        'Please sign in before requesting analytics.',
      );
    }
    final transport = httpClient ?? http.Client();
    try {
      final response = await transport
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AnalyticsException(
          'Your session could not be authorised. Please sign in again.',
        );
      }
      if (response.statusCode != 200) {
        throw const AnalyticsException(
          'Analytics are unavailable. Please try again later.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded.isEmpty) {
        throw const FormatException('Expected an analytics object');
      }
      return decoded;
    } on TimeoutException {
      throw const AnalyticsException(
        'The analytics server took too long. Please retry.',
      );
    } on FormatException {
      throw const AnalyticsException(
        'The analytics server returned an invalid response.',
      );
    } on http.ClientException {
      throw const AnalyticsException(
        'Cannot reach analytics. Check your connection and retry.',
      );
    } finally {
      if (httpClient == null) transport.close();
    }
  }
}

class AnalyticsException implements Exception {
  const AnalyticsException(this.message);
  final String message;
  @override
  String toString() => message;
}
