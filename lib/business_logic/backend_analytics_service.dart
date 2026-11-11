
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BackendAnalyticsService {
  BackendAnalyticsService({
    required this.client,
  });

  final SupabaseClient client;

  // Local FastAPI backend address.
  final String baseUrl =
      'https://fyp-financial-analytics-backend.onrender.com';

  // Retrieve financial analytics.
  Future<Map<String, dynamic>> getMyAnalytics() async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        'Please sign in before requesting analytics.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/my-analytics',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      throw Exception(
        'Authentication failed. Please sign in again.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Analytics request failed '
            '(${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid analytics response from backend.',
      );
    }

    return decoded;
  }

  // Retrieve Random Forest prediction and budget risk assessment.
  Future<Map<String, dynamic>> getMyPredictiveAnalytics() async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        'Please sign in before requesting predictions.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/api/v1/my-predictive-analytics',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      throw Exception(
        'Authentication failed. Please sign in again.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Predictive analytics request failed '
            '(${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid predictive analytics response.',
      );
    }

    // Debug response structure.
    debugPrint(
      'PREDICTIVE RESPONSE KEYS: ${decoded.keys.toList()}',
    );

    debugPrint(
      'EXPENDITURE PREDICTION: '
          '${decoded['expenditure_prediction']}',
    );

    debugPrint(
      'BUDGET RISK ASSESSMENT: '
          '${decoded['budget_risk_assessment']}',
    );

    return decoded;
  }
}
