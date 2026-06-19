import 'package:flint_ui/flint_ui.dart';

class DashboardHero extends StatelessComponent {
  final String role;

  DashboardHero({required this.role});

  @override
  View build() {
    return Container(
      dartStyle: const DartStyle(
        display: Display.flex,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.between,
        padding: EdgeInsets.all(32),
        radius: 20,
        border: Border(color: Color.rgba(255, 255, 255, 0.08), width: 1),
        background: 'linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%)',
        gap: 24,
        margin: EdgeInsets.only(bottom: 24),
        shadow: Shadow(
          x: 0,
          y: 20,
          blur: 40,
          spread: -20,
          color: Color.rgba(15, 23, 42, 0.3),
        ),
      ),
      children: [
        Column(
          dartStyle: const DartStyle(
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: 8,
            maxWidth: 600,
          ),
          children: [
            Text.h2(
              'Hosting Operations Dashboard',
              dartStyle: const DartStyle(
                fontSize: 26,
                fontWeight: 800,
                color: '#ffffff',
                letterSpacing: -0.5,
              ),
            ),
            Text.p(
              'Plans, subscriptions, users, servers, and provisioning work in one EuPanel control surface.',
              dartStyle: const DartStyle(
                fontSize: 14,
                color: '#94a3b8',
                lineHeight: 1.6,
              ),
            ),
          ],
        ),
        Row(
          dartStyle: const DartStyle(
            display: Display.flex,
            alignItems: AlignItems.center,
            gap: 12,
          ),
          children: [
            Link(
              href: '/dashboard/subscriptions',
              dartStyle: const DartStyle(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 10,
                background: 'linear-gradient(135deg, #0ea5e9, #2563eb)',
                color: '#ffffff',
                fontSize: 13,
                fontWeight: 700,
                cursor: Cursor.pointer,
                shadow: Shadow(
                    x: 0, y: 4, blur: 12, color: Color.rgba(14, 165, 233, 0.3)),
                transition: 'all 0.2s ease',
                hover: DartStyle(
                  transform: 'translateY(-2px)',
                  shadow: Shadow(
                      x: 0,
                      y: 8,
                      blur: 20,
                      color: Color.rgba(14, 165, 233, 0.45)),
                ),
              ),
              child: 'View subscriptions',
            ),
            Link(
              href: role == 'admin' ? '/dashboard/jobs' : '/dashboard/backups',
              dartStyle: const DartStyle(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 10,
                background: 'rgba(255, 255, 255, 0.08)',
                border:
                    Border(color: Color.rgba(255, 255, 255, 0.15), width: 1),
                color: '#f1f5f9',
                fontSize: 13,
                fontWeight: 700,
                cursor: Cursor.pointer,
                transition: 'all 0.2s ease',
                hover: DartStyle(
                  background: 'rgba(255, 255, 255, 0.15)',
                  border:
                      Border(color: Color.rgba(255, 255, 255, 0.25), width: 1),
                  transform: 'translateY(-1px)',
                ),
              ),
              child: role == 'admin' ? 'Provisioning jobs' : 'Backup records',
            ),
          ],
        ),
      ],
    );
  }
}
