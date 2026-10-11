enum RiskSeverity { warning, high }

class RiskAlert {
  final String title, description, label;
  final RiskSeverity severity;
  const RiskAlert({
    required this.title,
    required this.description,
    required this.label,
    this.severity = RiskSeverity.warning,
  });
}
