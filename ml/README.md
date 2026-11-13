# Expense category classifier

The app runs TF-IDF and multinomial Logistic Regression locally in Dart.
No network service, API key or Python installation is required on the phone.
The exported model is compiled into the app. Both manual expense descriptions
and receipt OCR text use the hybrid service. Income categories are unchanged.

## Starter model limitations

`training.csv` contains 144 authored synthetic examples, 24 per category.
These are not real transactions or a representative research dataset.
`evaluation.csv` contains 18 separately authored smoke examples. Its report
does not establish real-world accuracy or superiority to keyword matching.
Collect consented, anonymised, human-labelled English/Malay receipts before
claiming accuracy. Keep all examples of the same merchant in one split when
building independent training, validation and test sets. Include OCR mistakes,
ambiguous purchases and unrelated text. Compare macro F1, per-category
precision/recall, coverage and errors against the keyword baseline.

Grocery merchants map to Shopping according to this project's category policy.
Restaurants map to Food. Others is the abstention category, not a trained class.

The prototype accepts a prediction only if its score is at least 0.65, its
margin over the next category is at least 0.20, at least two distinct known
tokens are present and at least 40% of tokens are recognised. These conservative
initial thresholds are heuristics, not calibrated accuracy probabilities.
Validate/tune them with real data. Uncertain input falls back to keywords and
then Others. Receipt merchant text is considered before item text so groceries
do not become restaurant expenses merely because they include chicken.

Users can edit the category before saving. Changing the category on the manual
entry form disables automatic suggestions until the switch is enabled again.
The chosen category is passed to the existing save path. Saving a correction
does not retrain this model or upload OCR text. Existing expenses are not
recategorised.

## Reproduce / retrain (from project root)

```powershell
python -m venv .venv-ml
.\.venv-ml\Scripts\python.exe -m pip install -r ml/requirements.txt
.\.venv-ml\Scripts\python.exe ml/train.py
flutter test test/expense_classifier_test.dart
```

Training exports `lib/data/ml/expense_model_data.dart`, `evaluation_report.json`
and `parity_cases.json`. The Dart tests compare probabilities against Python
outputs to detect preprocessing/export drift, and exercise fallback and manual
category saving. Rebuild the app after exporting a replacement model.

References: [TF-IDF](https://scikit-learn.org/stable/modules/generated/sklearn.feature_extraction.text.TfidfVectorizer.html)
and [Logistic Regression](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html).
