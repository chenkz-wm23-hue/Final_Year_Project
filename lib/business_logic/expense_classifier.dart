import 'dart:convert';
import 'dart:math' as math;

import '../data/ml/expense_model_data.dart';

class CategoryPrediction {
  const CategoryPrediction(this.category, this.probabilities, this.accepted);
  final String category;
  final List<double> probabilities;
  final bool accepted;
}

/// Offline inference for the TF-IDF + multinomial logistic regression export.
/// Scores are model estimates, not calibrated guarantees of accuracy.
class ExpenseClassifier {
  ExpenseClassifier._(Map<String, dynamic> data)
    : classes = List<String>.from(data['classes'] as List),
      vocabulary = Map<String, int>.from(data['vocabulary'] as Map),
      idf = (data['idf'] as List).cast<num>().map((v) => v.toDouble()).toList(),
      weights = (data['weights'] as List)
          .map(
            (row) =>
                (row as List).cast<num>().map((v) => v.toDouble()).toList(),
          )
          .toList(),
      bias = (data['bias'] as List)
          .cast<num>()
          .map((v) => v.toDouble())
          .toList(),
      threshold = (data['threshold'] as num).toDouble(),
      margin = (data['margin'] as num).toDouble();

  static final bundled = ExpenseClassifier._(
    jsonDecode(expenseModelJson) as Map<String, dynamic>,
  );
  final List<String> classes;
  final Map<String, int> vocabulary;
  final List<double> idf, bias;
  final List<List<double>> weights;
  final double threshold, margin;

  CategoryPrediction? predict(String text) {
    final tokens = RegExp(r'[a-z][a-z0-9]+')
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
    if (tokens.isEmpty) return null;
    final counts = <int, double>{};
    var known = 0;
    for (final token in tokens) {
      final index = vocabulary[token];
      if (index == null) continue;
      known++;
      counts[index] = (counts[index] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final vector = counts.map((i, count) => MapEntry(i, count * idf[i]));
    final norm = math.sqrt(vector.values.fold<double>(0, (s, v) => s + v * v));
    final logits = List<double>.generate(
      classes.length,
      (c) =>
          bias[c] +
          vector.entries.fold<double>(
            0,
            (s, e) => s + weights[c][e.key] * e.value / norm,
          ),
    );
    final maxLogit = logits.reduce(math.max);
    final exp = logits.map((v) => math.exp(v - maxLogit)).toList();
    final sum = exp.reduce((a, b) => a + b);
    final probabilities = exp.map((v) => v / sum).toList();
    final ranked = List<int>.generate(classes.length, (i) => i)
      ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));
    final best = ranked.first;
    return CategoryPrediction(
      classes[best],
      probabilities,
      counts.length >= 2 &&
          known / tokens.length >= 0.4 &&
          probabilities[best] >= threshold &&
          probabilities[best] - probabilities[ranked[1]] >= margin,
    );
  }
}
