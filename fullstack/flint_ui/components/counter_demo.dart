import 'package:flint_ui/flint_ui.dart';

class CounterDemo extends FlintComponent {
  int count = 0;

  @override
  FlintNode build() {
    return Panel(
      title: 'Flint UI counter demo',
      description:
          'A small browser-side state island rendered without custom CSS.',
      dartStyle: _panelStyle,
      child: Column(
        dartStyle: const DartStyle(gap: 16),
        children: [
          Row(
            dartStyle: _rowStyle,
            children: [
              Text.p(
                'Use this as a simple proof that EuPanel can mix server data with reactive Flint UI components.',
                dartStyle: _bodyStyle,
              ),
              Container(
                dartStyle: _countStyle,
                child: Text.span(count, dartStyle: _countTextStyle),
              ),
            ],
          ),
          Row(
            dartStyle: _actionsStyle,
            children: [
              Button(
                child: 'Decrease',
                variant: ButtonVariant.outline,
                tone: Tone.neutral,
                onPressed: (_) => setState(() => count--),
              ),
              Button(
                child: 'Reset',
                variant: ButtonVariant.soft,
                tone: Tone.neutral,
                onPressed: (_) => setState(() => count = 0),
              ),
              Button(
                child: 'Increase',
                tone: Tone.primary,
                onPressed: (_) => setState(() => count++),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _panelStyle = DartStyle(
  border: Border(color: Color('#bfdbfe'), width: 1),
  background: Color('#ffffff'),
  shadow: Shadow(
    y: 18,
    blur: 36,
    spread: -24,
    color: Color.rgba(37, 99, 235, 0.22),
  ),
);

const _rowStyle = DartStyle(
  display: Display.flex,
  flexWrap: FlexWrap.wrap,
  alignItems: AlignItems.center,
  justifyContent: JustifyContent.between,
  gap: 16,
);

const _bodyStyle = DartStyle(
  maxWidth: 620,
  margin: EdgeInsets.all(0),
  color: Color('#475467'),
  lineHeight: 1.65,
);

const _countStyle = DartStyle(
  display: Display.flex,
  alignItems: AlignItems.center,
  justifyContent: JustifyContent.center,
  minWidth: 104,
  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 22),
  radius: 14,
  background: Color('#eff6ff'),
  border: Border(color: Color('#dbeafe'), width: 1),
);

const _countTextStyle = DartStyle(
  color: Color('#1d4ed8'),
  fontSize: 38,
  fontWeight: 800,
  lineHeight: 1,
);

const _actionsStyle = DartStyle(
  display: Display.flex,
  flexWrap: FlexWrap.wrap,
  gap: 10,
);
