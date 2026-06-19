import 'package:flint_ui/flint_ui.dart';

class DashboardPageTopbar extends StatelessComponent {
  DashboardPageTopbar({
    required this.title,
    required this.subtitle,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Object? actions;

  @override
  View build() {
    return Topbar(
      title: title,
      subtitle: subtitle,
      dartStyle: _style,
      actions: actions,
    );
  }
}

const _style = DartStyle(
  display: Display.flex,
  alignItems: AlignItems.center,
  justifyContent: JustifyContent.between,
  margin: EdgeInsets.only(bottom: 24),
);
