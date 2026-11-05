import '../data/models/keyword.dart';

class ExpenseCategorisation {
  final List<CategoryKeyword> keywords;
  const ExpenseCategorisation(this.keywords);

  static const _commonKeywords = <String, String>{
    'kfc': 'Food',
    'petron': 'Fuel',
    'petronas': 'Fuel',
    'bhp': 'Fuel',
    'petrol': 'Fuel',
    'diesel': 'Fuel',
    'caltex': 'Fuel',
    'shell': 'Fuel',
    'fuel': 'Fuel',
    'food': 'Food',
    'restaurant': 'Food',
    'cafe': 'Food',
    'grocer': 'Shopping',
    'grocers': 'Shopping',
    'grocery': 'Shopping',
    'groceries': 'Shopping',
    'supermarket': 'Shopping',
    'hypermarket': 'Shopping',
    'minimart': 'Shopping',
    'mini market': 'Shopping',
    'pasar raya': 'Shopping',
    'pasar mini': 'Shopping',
    'tesco': 'Shopping',
    'lotus': 'Shopping',
    'aeon': 'Shopping',
    'mydin': 'Shopping',
    '99 speedmart': 'Shopping',
    'shopee': 'Shopping',
    'lazada': 'Shopping',
    'uniqlo': 'Shopping',
    'mr diy': 'Shopping',
    'clothing': 'Shopping',
    'shoes': 'Shopping',
    'mcdonald': 'Food',
    'mcdonalds': 'Food',
    'mcdonald s': 'Food',
    'pizza hut': 'Food',
    'domino': 'Food',
    'subway': 'Food',
    'starbucks': 'Food',
    'tealive': 'Food',
    'zus coffee': 'Food',
    'grabfood': 'Food',
    'foodpanda': 'Food',
    'restoran': 'Food',
    'kedai makan': 'Food',
    'kopitiam': 'Food',
    'bakery': 'Food',
    'nasi': 'Food',
    'noodles': 'Food',
    'breakfast': 'Food',
    'lunch': 'Food',
    'dinner': 'Food',
    'bhpetrol': 'Fuel',
    'minyak petrol': 'Fuel',
    'ron95': 'Fuel',
    'ron97': 'Fuel',
    'grab': 'Transport',
    'rapidkl': 'Transport',
    'mrt': 'Transport',
    'lrt': 'Transport',
    'ktm': 'Transport',
    'taxi': 'Transport',
    'bus': 'Transport',
    'train': 'Transport',
    'parking': 'Transport',
    'toll': 'Transport',
    'tol': 'Transport',
    'pharmacy': 'Healthcare',
    'farmasi': 'Healthcare',
    'clinic': 'Healthcare',
    'klinik': 'Healthcare',
    'hospital': 'Healthcare',
    'dental': 'Healthcare',
    'dentist': 'Healthcare',
    'watsons': 'Healthcare',
    'guardian': 'Healthcare',
    'caring pharmacy': 'Healthcare',
    'medicine': 'Healthcare',
    'ubat': 'Healthcare',
    'tgv': 'Entertainment',
    'gsc': 'Entertainment',
    'karaoke': 'Entertainment',
    'bowling': 'Entertainment',
    'arcade': 'Entertainment',
    'concert': 'Entertainment',
    'meal': 'Food',
    'toy': 'Entertainment',
    'toys': 'Entertainment',
    'movie': 'Entertainment',
    'cinema': 'Entertainment',
    'game': 'Entertainment',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'etc': 'Others',
  };

  String suggest(String description) {
    return suggestReceipt([description]);
  }

  String suggestReceipt(List<String> lines) {
    // Check the merchant header first, then item lines. Match whole words so
    // a payment word such as “cash” cannot match a shorter merchant keyword.
    final rules = {
      for (final k in keywords) k.word.toLowerCase(): k.category,
      ..._commonKeywords,
      'coat': 'Shopping',
      'dress': 'Shopping',
      'handbag': 'Shopping',
      'crossbody bag': 'Shopping',
      'milk': 'Food',
      'muesli': 'Food',
      'chocolate': 'Food',
      'mushrooms': 'Food',
      'garlic': 'Food',
      'steaks': 'Food',
      'chicken': 'Food',
      'toast': 'Food',
      'earl grey': 'Food',
    };
    // Prefer specific merchant phrases over short words on the same line.
    final orderedRules = rules.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final line in lines) {
      final words = line.toLowerCase().split(RegExp('[^a-z0-9]+'));
      final phrase = ' ${words.join(' ')} ';
      for (final rule in orderedRules) {
        final keyword = rule.key.replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
        if (keyword.isEmpty) continue;
        // OCR sometimes joins a merchant or product to the following noun.
        final joined = [
          'station',
          'restaurant',
          'receipt',
          'store',
        ].any((suffix) => words.contains('$keyword$suffix'));
        if (phrase.contains(' $keyword ') || joined) {
          return rule.value;
        }
      }
    }
    return 'Others';
  }
}
