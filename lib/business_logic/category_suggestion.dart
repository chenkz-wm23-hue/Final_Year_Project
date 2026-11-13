import 'expense_categorisation.dart';
import 'expense_classifier.dart';

enum CategorySuggestionSource { machineLearning, keyword, unknown }

class CategorySuggestion {
  const CategorySuggestion(this.category, this.source);
  final String category;
  final CategorySuggestionSource source;
  String get guidance => switch (source) {
    CategorySuggestionSource.machineLearning =>
      'Suggested by ML. Check or change the category before saving.',
    CategorySuggestionSource.keyword =>
      'Suggested from keywords. Check or change the category before saving.',
    CategorySuggestionSource.unknown =>
      'No clear match. Please choose the category before saving.',
  };
}

class HybridExpenseCategorisation {
  const HybridExpenseCategorisation(this.fallback, {this.enableModel = true});
  final ExpenseCategorisation fallback;
  final bool enableModel;

  CategorySuggestion suggest(String text) => suggestReceipt([text]);

  CategorySuggestion suggestReceipt(List<String> lines) {
    // Evaluate the merchant separately, before item text can dominate it.
    final nonEmpty = lines.where((line) => line.trim().isNotEmpty).toList();
    if (enableModel && nonEmpty.isNotEmpty) {
      for (final text in [nonEmpty.first, nonEmpty.join(' ')]) {
        final prediction = ExpenseClassifier.bundled.predict(text);
        if (prediction != null && prediction.accepted) {
          return CategorySuggestion(
            prediction.category,
            CategorySuggestionSource.machineLearning,
          );
        }
        // A recognisable merchant with insufficient ML evidence uses keywords.
        if (text == nonEmpty.first && nonEmpty.length > 1) {
          final merchant = fallback.suggest(text);
          if (merchant != 'Others') {
            return CategorySuggestion(
              merchant,
              CategorySuggestionSource.keyword,
            );
          }
        }
      }
    }
    final category = fallback.suggestReceipt(lines);
    return CategorySuggestion(
      category,
      category == 'Others'
          ? CategorySuggestionSource.unknown
          : CategorySuggestionSource.keyword,
    );
  }
}
