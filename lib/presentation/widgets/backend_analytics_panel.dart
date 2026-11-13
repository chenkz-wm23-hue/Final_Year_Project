import 'package:flutter/material.dart';

import '../../business_logic/backend_analytics_service.dart';
import '../state/auth_scope.dart';
import '../state/expense_store.dart';
import 'app_card.dart';

class BackendAnalyticsPanel extends StatefulWidget {
  const BackendAnalyticsPanel({super.key, this.service});
  final BackendAnalyticsService? service;

  @override
  State<BackendAnalyticsPanel> createState() => _BackendAnalyticsPanelState();
}

class _BackendAnalyticsPanelState extends State<BackendAnalyticsPanel> {
  late BackendAnalyticsService analyticsService;
  late Future<Map<String, dynamic>> analyticsFuture;
  late Future<Map<String, dynamic>> predictiveAnalyticsFuture;

  Object? _client;
  ExpenseStore? _store;
  int? _revision;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = widget.service?.client ?? AuthScope.maybeOf(context)?.client;
    final store = ExpenseScope.of(context);
    if (client == null) return;
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    if (store.month.year != now.year || store.month.month != now.month) return;
    if (!identical(_client, client) ||
        !identical(_store, store) ||
        _revision != store.dataRevision) {
      _client = client;
      _store = store;
      _revision = store.dataRevision;
      analyticsService =
          widget.service ?? BackendAnalyticsService(client: client);
      analyticsFuture = analyticsService.getMyAnalytics();
      predictiveAnalyticsFuture = analyticsService.getMyPredictiveAnalytics();
    }
  }

  void retryAnalytics() {
    setState(() {
      analyticsFuture = analyticsService.getMyAnalytics();
      predictiveAnalyticsFuture = analyticsService.getMyPredictiveAnalytics();
    });
  }

  double numberValue(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    return number != null && number.isFinite ? number : 0;
  }

  String formatMoney(dynamic value) {
    return 'RM ${numberValue(value).toStringAsFixed(2)}';
  }

  Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
    }
    return {};
  }

  Widget monthlyBudgetCard() {
    final store = ExpenseScope.of(context);
    if (store.budget <= 0) {
      return AppCard(
        child: Text(
          'Budget not set • ${store.monthLabel}. Set your spending limit on the Budget screen. Recorded expenses: ${money(store.expense)}.',
        ),
      );
    }
    final budgetLimit = store.budget;
    final percentageUsed = budgetLimit > 0
        ? store.expense / budgetLimit * 100
        : 0.0;
    final remainingBudget = store.remaining;
    final status = store.expense > budgetLimit
        ? 'exceeded'
        : store.expense == budgetLimit
        ? 'full budget used'
        : percentageUsed >= 80
        ? 'warning'
        : 'within budget';
    return Column(
      children: [
        // Budget analysis
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Budget Analysis',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Text(
                store.repository.budgetFor(store.month) == null
                    ? 'Budget not set • ${store.monthLabel}'
                    : 'Saved budget • ${store.monthLabel}',
              ),
              const Text(
                'Calculated from your monthly expenses, not an ML forecast.',
              ),
              const SizedBox(height: 16),
              _analyticsValue(
                'Budget Limit',
                formatMoney(budgetLimit),
                Colors.indigo,
              ),
              const SizedBox(height: 12),
              _analyticsValue(
                'Current Spending',
                formatMoney(store.expense),
                Colors.deepOrange,
              ),
              const SizedBox(height: 12),
              _analyticsValue(
                'Remaining Budget',
                formatMoney(remainingBudget),
                remainingBudget < 0 ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (percentageUsed / 100).clamp(0.0, 1.0).toDouble(),
                minHeight: 9,
                color: percentageUsed > 100
                    ? Colors.red
                    : percentageUsed >= 80
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(height: 8),
              Text('${percentageUsed.toStringAsFixed(2)}% of budget used'),
              const SizedBox(height: 12),
              Text(
                'Status: $status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status == 'exceeded'
                      ? Colors.red
                      : (status == 'warning' || status == 'full budget used')
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget analyticsCard(Map<String, dynamic> data) {
    final summary = asMap(data['financial_summary']);

    final categories = data['category_analysis'] is List
        ? data['category_analysis'] as List
        : [];

    final insights = data['financial_insights'] is List
        ? data['financial_insights'] as List
        : [];

    final averageDaily = numberValue(data['average_daily_spending']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Financial Analytics',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Financial summary
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Summary (all time)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _analyticsValue(
                      'Total Income',
                      formatMoney(summary['total_income']),
                      Colors.teal,
                    ),
                  ),
                  Expanded(
                    child: _analyticsValue(
                      'Total Expenses',
                      formatMoney(summary['total_expenses']),
                      Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _analyticsValue(
                'Overall Balance',
                formatMoney(summary['balance']),
                numberValue(summary['balance']) < 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Average daily spending
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Average Daily Spending',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                formatMoney(averageDaily),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Text('Average expenditure per day this month'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Category analysis
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spending by Category (all time)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                const Text('No category spending data available.')
              else
                ...categories.map((item) {
                  final category = asMap(item);
                  final name = category['category']?.toString() ?? 'Other';
                  final amount = numberValue(category['total_spending']);
                  final percentage = numberValue(category['percentage']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(formatMoney(amount)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (percentage / 100).clamp(0.0, 1.0).toDouble(),
                          minHeight: 7,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(2)}% of expenses',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Financial insights
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Insights',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (insights.isEmpty)
                const Text('No financial insights available.')
              else
                ...insights.map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(insight.toString())),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: retryAnalytics,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Analytics'),
          ),
        ),
      ],
    );
  }

  Widget predictiveAnalyticsCard(Map<String, dynamic> data) {
    final prediction = asMap(data['expenditure_prediction']);
    final predictionStatus =
        prediction['prediction_status']?.toString() ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Predictive Analytics',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Expenditure Prediction',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (predictionStatus == 'success') ...[
                Text(
                  formatMoney(prediction['predicted_spending']),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const Text('Predicted expenditure for the next month'),
                const SizedBox(height: 12),
                if (prediction['model'] != null)
                  Text('Model: ${prediction['model']}'),
                if (prediction['mean_absolute_error'] != null)
                  Text(
                    'Mean absolute error: '
                    '${formatMoney(prediction['mean_absolute_error'])}',
                  ),
                if (prediction['training_months'] != null)
                  Text(
                    'Training data rows: '
                    '${prediction['training_months']}',
                  ),
              ] else ...[
                const Text(
                  'Prediction is not available yet.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prediction['message']?.toString() ?? 'At least 9 completed months of spending history are required to generate a prediction.',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPredictiveAnalyticsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: predictiveAnalyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: Column(
              children: [
                Text(
                  'AI Predictive Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Generating expenditure prediction...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Predictive Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to retrieve predictive analytics.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: retryAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const AppCard(
            child: Text('No predictive analytics data available.'),
          );
        }

        return predictiveAnalyticsCard(snapshot.data!);
      },
    );
  }

  Widget _analyticsValue(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget buildAnalyticsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(
            child: Column(
              children: [
                Text(
                  'AI Financial Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Analysing your financial data...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Financial Analytics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to retrieve analytics.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: retryAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const AppCard(child: Text('No analytics data available.'));
        }

        return analyticsCard(snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);
    if (widget.service == null && AuthScope.maybeOf(context) == null) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    if (store.month.year != now.year || store.month.month != now.month) {
      return const AppCard(
        child: Text(
          'Online analytics describe the current month. Select the current month to view them.',
        ),
      );
    }
    if (_client == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        monthlyBudgetCard(),
        buildAnalyticsSection(),
        const SizedBox(height: 20),
        buildPredictiveAnalyticsSection(),
      ],
    );
  }
}
