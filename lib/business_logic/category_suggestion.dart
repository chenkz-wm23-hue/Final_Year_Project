
import 'expense_categorisation.dart';

class CategorySuggestion {
  final String category;
  final String guidance;

  const CategorySuggestion({
    required this.category,
    required this.guidance,
  });
}

class HybridExpenseCategorisation {
  final ExpenseCategorisation categorisation;

  const HybridExpenseCategorisation(this.categorisation);

  CategorySuggestion suggest(String description) {
    final category = categorisation.suggest(description);

    return CategorySuggestion(
      category: category,
      guidance: 'Category suggested using keyword matching.',
    );
  }

  CategorySuggestion suggestReceipt(List<String> lines) {
    final category = categorisation.suggestReceipt(lines);

    return CategorySuggestion(
      category: category,
      guidance: 'Category suggested from receipt text using keyword matching.',
    );
  }
}
