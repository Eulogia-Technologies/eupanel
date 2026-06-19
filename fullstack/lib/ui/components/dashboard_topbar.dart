import 'package:flint_ui/flint_ui.dart';

class DashboardTopbar extends StatelessComponent {
  final String role;

  DashboardTopbar({required this.role});

  @override
  View build() {
    return Container(
      dartStyle: const DartStyle(
        display: Display.flex,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.between,
        margin: EdgeInsets.only(bottom: 24),
      ),
      children: [
        Column(
          dartStyle: const DartStyle(
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: 4,
          ),
          children: [
            Row(
              dartStyle: const DartStyle(
                display: Display.flex,
                alignItems: AlignItems.center,
                gap: 8,
              ),
              children: [
                Text.strong(
                  'Hosting Control Center',
                  dartStyle: const DartStyle(
                    fontSize: 24,
                    fontWeight: 800,
                    color: '#0f172a',
                    letterSpacing: -0.6,
                  ),
                ),
                Container(
                  dartStyle: DartStyle(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    radius: 999,
                    background: role == 'admin' ? '#eff6ff' : '#f0fdf4',
                    color: role == 'admin' ? '#1d4ed8' : '#15803d',
                    fontSize: 11,
                    fontWeight: 700,
                    textTransform: TextTransform.uppercase,
                    letterSpacing: 0.5,
                  ),
                  child: Text(role),
                ),
              ],
            ),
            Text.span(
              'EuPanel Node Overview',
              dartStyle: const DartStyle(
                fontSize: 14,
                color: '#64748b',
              ),
            ),
          ],
        ),
        Link(
          href: '/docs',
          dartStyle: const DartStyle(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            radius: 10,
            background: '#ffffff',
            border: Border(color: Color('#e2e8f0'), width: 1),
            color: '#475569',
            fontSize: 13,
            fontWeight: 700,
            cursor: Cursor.pointer,
            shadow:
                Shadow(x: 0, y: 1, blur: 2, color: Color.rgba(0, 0, 0, 0.05)),
            transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
            hover: DartStyle(
              background: '#f8fafc',
              color: '#0f172a',
              border: Border(color: Color('#cbd5e1'), width: 1),
              transform: 'translateY(-1px)',
              shadow:
                  Shadow(x: 0, y: 4, blur: 8, color: Color.rgba(0, 0, 0, 0.05)),
            ),
          ),
          child: 'API Docs',
        ),
      ],
    );
  }
}
