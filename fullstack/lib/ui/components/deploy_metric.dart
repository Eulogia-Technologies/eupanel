import 'package:flint_ui/flint_ui.dart';

class DeployMetric extends FlintComponent {
  String label;
  String value;

  DeployMetric({
    required this.label,
    required this.value,
  });

  @override
  void updateFrom(covariant DeployMetric next) {
    label = next.label;
    value = next.value;
  }

  @override
  FlintNode build() {
    return Container(
      dartStyle: const DartStyle(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 4,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        background: '#f8fafc',
        radius: 10,
        border: Border(color: Color('#e2e8f0'), width: 1),
        transition: 'all 0.2s ease',
        hover: DartStyle(
          background: '#f1f5f9',
          border: Border(color: Color('#cbd5e1'), width: 1),
        ),
      ),
      children: [
        Text.span(
          label,
          dartStyle: const DartStyle(
            fontSize: 10,
            color: Color('#64748b'),
            fontWeight: 700,
            textTransform: TextTransform.uppercase,
            letterSpacing: 0.5,
          ),
        ),
        Text.strong(
          value,
          dartStyle: const DartStyle(
            fontSize: 13,
            color: Color('#0f172a'),
            fontFamily: 'monospace',
            fontWeight: 700,
          ),
        ),
      ],
    );
  }
}
