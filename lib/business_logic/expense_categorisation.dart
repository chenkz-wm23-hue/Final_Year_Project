import '../data/models/keyword.dart';

class ExpenseCategorisation {
  final List<CategoryKeyword> keywords;
  const ExpenseCategorisation(this.keywords);
  String suggest(String description) {
    final text = description.toLowerCase();
    for (final keyword in keywords) {
      if (text.contains(keyword.word.toLowerCase())) return keyword.category;
    }
    return 'Others';
  }
}
