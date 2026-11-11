
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../business_logic/backend_analytics_service.dart';
import '../state/expense_store.dart';
import '../widgets/app_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/live_transaction_tile.dart';
import '../widgets/category_summary.dart';
import '../widgets/finance_charts.dart';
import 'income_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_screen.dart';
import 'recommendations_screen.dart';
import 'risk_alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final BackendAnalyticsService analyticsService;
  late Future<Map<String, dynamic>> analyticsFuture;
  late Future<Map<String, dynamic>> predictiveAnalyticsFuture;

  // Persistent dashboard scroll controller.
  final ScrollController _dashboardScrollController =
  ScrollController();

  @override
  void initState() {
    super.initState();

    analyticsService = BackendAnalyticsService(
      client: Supabase.instance.client,
    );

    analyticsFuture = analyticsService.getMyAnalytics();
    predictiveAnalyticsFuture =
        analyticsService.getMyPredictiveAnalytics();
  }

  @override
  void dispose() {
    _dashboardScrollController.dispose();
    super.dispose();
  }

  void retryAnalytics() {
    setState(() {
      analyticsFuture = analyticsService.getMyAnalytics();
      predictiveAnalyticsFuture =
          analyticsService.getMyPredictiveAnalytics();
    });
  }

  double numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String formatMoney(dynamic value) {
    return 'RM ${numberValue(value).toStringAsFixed(2)}';
  }

  Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  Widget analyticsCard(Map<String, dynamic> data) {
    final summary = asMap(data['financial_summary']);
    final budget = asMap(data['budget_analysis']);

    final categories = data['category_analysis'] is List
        ? data['category_analysis'] as List
        : [];

    final insights = data['financial_insights'] is List
        ? data['financial_insights'] as List
        : [];

    final averageDaily = numberValue(
      data['average_daily_spending'],
    );

    final budgetLimit = numberValue(budget['budget_limit']);
    final percentageUsed = numberValue(budget['percentage_used']);
    final remainingBudget = numberValue(budget['remaining_budget']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Financial Analytics',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Financial summary
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial Summary',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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
                numberValue(summary['balance']) < 0
                    ? Colors.red
                    : Colors.green,
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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
              const Text(
                'Average expenditure per day this month',
              ),
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
                'Spending by Category',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                const Text('No category spending data available.')
              else
                ...categories.map((item) {
                  final category = asMap(item);
                  final name =
                      category['category']?.toString() ?? 'Other';
                  final amount = numberValue(
                    category['total_spending'],
                  );
                  final percentage = numberValue(
                    category['percentage'],
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                          value: (percentage / 100)
                              .clamp(0.0, 1.0)
                              .toDouble(),
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

        // Budget analysis
        if (budget.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Budget Analysis',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
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
                  formatMoney(budget['actual_spending']),
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
                  value: (percentageUsed / 100)
                      .clamp(0.0, 1.0)
                      .toDouble(),
                  minHeight: 9,
                  color: percentageUsed >= 100
                      ? Colors.red
                      : percentageUsed >= 80
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentageUsed.toStringAsFixed(2)}% of budget used',
                ),
                const SizedBox(height: 12),
                Text(
                  'Status: ${budget['status'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: budget['status'] == 'exceeded'
                        ? Colors.red
                        : budget['status'] == 'warning'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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
                        Expanded(
                          child: Text(insight.toString()),
                        ),
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
    final risk = asMap(data['budget_risk_assessment']);

    final predictionStatus =
        prediction['prediction_status']?.toString() ?? 'unknown';
    final riskLevel = risk['risk_level']?.toString() ?? 'unknown';

    Color riskColor;

    switch (riskLevel) {
      case 'low':
        riskColor = Colors.green;
        break;
      case 'medium':
        riskColor = Colors.orange;
        break;
      case 'high':
        riskColor = Colors.red;
        break;
      default:
        riskColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Predictive Analytics',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Expenditure Prediction',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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
                const Text(
                  'Predicted expenditure for the next month',
                ),
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
                  prediction['message']?.toString() ??
                      'At least 9 completed months of spending history are required to generate a prediction.',
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget Risk Assessment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                riskLevel.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),

              if (risk['message'] != null) ...[
                const SizedBox(height: 8),
                Text(risk['message'].toString()),
              ],

              if (risk.containsKey('actual_spending')) ...[
                const SizedBox(height: 14),
                _analyticsValue(
                  'Current Spending',
                  formatMoney(risk['actual_spending']),
                  Colors.deepOrange,
                ),
              ],

              if (risk.containsKey('budget_limit')) ...[
                const SizedBox(height: 12),
                _analyticsValue(
                  'Budget Limit',
                  formatMoney(risk['budget_limit']),
                  Colors.indigo,
                ),
              ],

              if (risk.containsKey('percentage_used')) ...[
                const SizedBox(height: 12),
                _analyticsValue(
                  'Budget Used',
                  '${numberValue(risk['percentage_used']).toStringAsFixed(2)}%',
                  riskColor,
                ),
              ],

              if (risk.containsKey('projected_spending') &&
                  risk['projected_spending'] != null) ...[
                const SizedBox(height: 12),
                _analyticsValue(
                  'Projected Month-End Spending',
                  formatMoney(risk['projected_spending']),
                  riskColor,
                ),
              ],

              if (risk.containsKey('remaining_days')) ...[
                const SizedBox(height: 12),
                Text('Remaining days: ${risk['remaining_days']}'),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _analyticsValue(
      String label,
      String value,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
          return const AppCard(
            child: Text('No analytics data available.'),
          );
        }

        return analyticsCard(snapshot.data!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ExpenseScope.of(context);

    return ListView(
      controller: _dashboardScrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        Text(
          'Hi, ${store.name}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text('Your money at a glance'),
        const MonthSelector(),
        const SizedBox(height: 16),

        // Recorded cash flow
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recorded cash flow'),
              Text(
                money(store.balance),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  Text(
                    'Income\n${money(store.income)}',
                    style: const TextStyle(color: Colors.teal),
                  ),
                  Text(
                    'Expenses\n${money(store.expense)}',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Income minus expenses. Your budget is a spending limit, not income.',
              ),
              if (store.income == 0 && store.expense > 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'No received income recorded this month. Add income when you receive it.',
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const TransactionFormScreen(income: true),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Manage Income'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Income'),
                          ),
                          body: const SafeArea(
                            child: IncomeScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Monthly budget
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly budget · ${money(store.budget)}'),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: store.ratio.clamp(0, 1).toDouble(),
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Text(
                store.remaining < 0
                    ? '${money(-store.remaining)} over budget'
                    : '${money(store.remaining)} budget remaining',
              ),
              const SizedBox(height: 6),
              Text(
                store.remaining < 0
                    ? 'Spending exceeds your budget.'
                    : store.remaining == 0
                    ? 'You have used your full budget.'
                    : 'Your spending is within budget.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Python backend analytics
        buildAnalyticsSection(),

        const SizedBox(height: 20),

        // Python backend predictive analytics
        buildPredictiveAnalyticsSection(),

        const SizedBox(height: 20),

        AppCard(
          child: CashFlowChart(
            income: store.income,
            expense: store.expense,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Spending summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (store.expense == 0)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add your first expense to see your spending summary.',
            ),
          ),

        ...store.categoryTotals.entries.map(
              (e) => CategorySummary(
            category: e.key,
            amount: e.value,
            total: store.expense,
          ),
        ),

        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Recommendations'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Recommendations'),
                    ),
                    body: const RecommendationsScreen(),
                  ),
                ),
              ),
            ),
            ActionChip(
              label: const Text('Risk Alerts'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Risk Alerts'),
                    ),
                    body: const RiskAlertsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent transactions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Transactions'),
                    ),
                    body: const TransactionsScreen(),
                  ),
                ),
              ),
              child: const Text('View all'),
            ),
          ],
        ),

        ...store.monthly.take(5).map(
              (e) => LiveTransactionTile(entry: e),
        ),
      ],
    );
  }
}