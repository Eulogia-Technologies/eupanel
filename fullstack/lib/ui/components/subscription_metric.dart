import 'package:flint_ui/flint_ui.dart';
import 'package:universal_web/web.dart' as web;

class SubscriptionMetric extends StatelessComponent {
  final String label;
  final String value;
  final bool copyable;

  SubscriptionMetric({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  View build() {
    return Container(
      dartStyle: const DartStyle(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 4,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        background: '#f8fafc',
        radius: 10,
        border: Border(color: Color('#e2e8f0'), width: 1),
        position: Position.relative,
        transition: 'all 0.2s ease',
        hover: DartStyle(
          background: '#f1f5f9',
          border: Border(color: Color('#cbd5e1'), width: 1),
        ),
      ),
      children: [
        Row(
          dartStyle: const DartStyle(
            alignItems: AlignItems.center,
            justifyContent: JustifyContent.between,
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
            if (copyable &&
                value.isNotEmpty &&
                value != '********' &&
                value != 'pending')
              Button(
                dartStyle: const DartStyle(
                  background: 'transparent',
                  color: Color('#2563eb'),
                  fontSize: 11,
                  fontWeight: 700,
                  cursor: Cursor.pointer,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  radius: 4,
                  transition: 'all 0.15s ease',
                  hover: DartStyle(
                    background: 'rgba(37, 99, 235, 0.08)',
                    color: Color('#1d4ed8'),
                  ),
                ),
                onPressed: (_) {
                  _copyToClipboard(value);
                },
                child: Text('Copy'),
              ),
          ],
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

  void _copyToClipboard(String text) {
    (web.window.navigator as dynamic).clipboard.writeText(text);
    web.window.alert('Copied to clipboard!');
  }
}
