import 'package:flint_ui/flint_ui.dart';

class DashboardModuleCard extends StatelessComponent {
  final Map<String, dynamic> module;

  DashboardModuleCard({required this.module});

  @override
  View build() {
    final title = module['title']?.toString() ?? 'Module';
    final body = module['body']?.toString() ?? '';
    final emoji = _getEmoji(title);

    return Link(
      href: module['href']?.toString() ?? '#',
      dartStyle: const DartStyle(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 12,
        padding: EdgeInsets.all(20),
        radius: 16,
        background: '#ffffff',
        border: Border(color: Color('#e2e8f0'), width: 1),
        shadow: Shadow(
          x: 0,
          y: 4,
          blur: 12,
          spread: 0,
          color: Color.rgba(0, 0, 0, 0.02),
        ),
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        hover: DartStyle(
          transform: 'translateY(-4px)',
          border: Border(color: Color('#bfdbfe'), width: 1),
          shadow: Shadow(
            x: 0,
            y: 16,
            blur: 32,
            spread: -8,
            color: Color.rgba(37, 99, 235, 0.08),
          ),
        ),
      ),
      children: [
        Container(
          dartStyle: const DartStyle(
            display: Display.flex,
            alignItems: AlignItems.center,
            justifyContent: JustifyContent.center,
            width: 44,
            height: 44,
            radius: 12,
            background: '#eff6ff',
            fontSize: 20,
          ),
          child: Text(emoji),
        ),
        Column(
          dartStyle: const DartStyle(
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: 4,
          ),
          children: [
            Text.strong(
              title,
              dartStyle: const DartStyle(
                fontSize: 16,
                fontWeight: 700,
                color: '#0f172a',
              ),
            ),
            Text.p(
              body,
              dartStyle: const DartStyle(
                fontSize: 13,
                color: '#64748b',
                lineHeight: 1.5,
                margin: EdgeInsets.all(0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getEmoji(String title) {
    final t = title.toLowerCase();
    if (t.contains('plan')) return '📦';
    if (t.contains('subscription')) return '🚀';
    if (t.contains('website') || t.contains('domain')) return '🌐';
    if (t.contains('dns')) return '🔌';
    if (t.contains('database') || t.contains('db')) return '🗄️';
    if (t.contains('ssl') || t.contains('cert')) return '🛡️';
    if (t.contains('backup')) return '💾';
    if (t.contains('server')) return '🖥️';
    if (t.contains('customer')) return '👥';
    if (t.contains('job')) return '⚡';
    return '⚙️';
  }
}
