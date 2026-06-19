import 'package:flint_ui/flint_ui.dart';

class EuPanelDashboardSidebar extends StatelessComponent {
  EuPanelDashboardSidebar({
    required this.role,
  });

  final String role;

  @override
  View build() {
    final activePath = _normalizePath(currentUri.path);
    final isLoggedIn = authSession.isLoggedIn;
    final user = authSession.user;
    final name = user['name']?.toString() ?? 'Admin User';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A';

    return Column(
      dartStyle: const DartStyle(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        height: '100%',
        gap: 24,
      ),
      children: [
        Sidebar(
          items: _items,
          activePath: activePath,
          itemDartStyle: const DartStyle(
            color: '#94a3b8',
            background: 'transparent',
            fontWeight: 500,
            fontSize: 14,
            radius: 10,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
            hover: DartStyle(
              color: '#ffffff',
              background: 'rgba(255, 255, 255, 0.05)',
              transform: 'translateX(6px)',
            ),
          ),
          activeItemDartStyle: const DartStyle(
            color: '#ffffff',
            background: 'linear-gradient(135deg, #0ea5e9, #2563eb)',
            fontWeight: 700,
            fontSize: 14,
            radius: 10,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shadow: '0 8px 20px rgba(14, 165, 233, 0.25)',
            transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
            hover: DartStyle(
              transform: 'scale(1.02) translateX(4px)',
            ),
          ),
          style: const {
            'width': '100%',
            'padding': '0',
          },
        ),
        if (isLoggedIn)
          Container(
            dartStyle: const DartStyle(
              margin: EdgeInsets.only(top: 'auto'),
              padding: EdgeInsets.all(12),
              radius: 12,
              background: 'rgba(255, 255, 255, 0.03)',
              border: Border(
                width: 1,
                style: 'solid',
                color: 'rgba(255, 255, 255, 0.06)',
              ),
              display: Display.flex,
              alignItems: AlignItems.center,
              gap: 12,
            ),
            children: [
              Container(
                dartStyle: const DartStyle(
                  display: Display.flex,
                  alignItems: AlignItems.center,
                  justifyContent: JustifyContent.center,
                  width: 38,
                  height: 38,
                  radius: 19,
                  background: 'linear-gradient(135deg, #a855f7, #ec4899)',
                  color: '#ffffff',
                  fontWeight: 700,
                  fontSize: 14,
                ),
                child: Text(initials),
              ),
              Column(
                dartStyle: const DartStyle(
                  display: Display.flex,
                  flexDirection: FlexDirection.column,
                  gap: 2,
                  flex: 1,
                ),
                children: [
                  Text.strong(
                    name,
                    dartStyle: const DartStyle(
                      color: '#ffffff',
                      fontSize: 13,
                      fontWeight: 600,
                    ),
                  ),
                  Text.span(
                    role.toUpperCase(),
                    dartStyle: const DartStyle(
                      color: '#38bdf8',
                      fontSize: 10,
                      fontWeight: 700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Link(
                href: '/login',
                props: {
                  'onClick': (_) {
                    authSession.clear();
                  }
                },
                dartStyle: const DartStyle(
                  color: '#f87171',
                  fontSize: 11,
                  fontWeight: 700,
                  cursor: Cursor.pointer,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  radius: 8,
                  background: 'rgba(239, 68, 68, 0.1)',
                  transition: 'all 0.2s ease',
                  hover: DartStyle(
                    background: 'rgba(239, 68, 68, 0.2)',
                    color: '#ef4444',
                    transform: 'scale(1.05)',
                  ),
                ),
                child: 'Logout',
              ),
            ],
          )
        else
          Link(
            href: '/login',
            dartStyle: const DartStyle(
              margin: EdgeInsets.only(top: 'auto'),
              color: '#ffffff',
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              radius: 10,
              background: 'linear-gradient(135deg, #0ea5e9, #2563eb)',
              textAlign: TextAlign.center,
              fontWeight: 700,
              fontSize: 14,
              shadow: '0 4px 12px rgba(37, 99, 235, 0.2)',
              transition: 'all 0.2s ease',
              hover: DartStyle(
                transform: 'translateY(-1px)',
                shadow: '0 6px 16px rgba(37, 99, 235, 0.3)',
              ),
            ),
            child: 'Sign in',
          ),
      ],
    );
  }

  List<SidebarItem> get _items {
    return [
      const SidebarItem(label: 'Overview', href: '/dashboard'),
      const SidebarItem(
          label: 'Subscriptions', href: '/dashboard/subscriptions'),
      const SidebarItem(label: 'Websites', href: '/dashboard/websites-domains'),
      const SidebarItem(label: 'DNS', href: '/dashboard/dns'),
      const SidebarItem(label: 'SSL', href: '/dashboard/ssl'),
      const SidebarItem(label: 'File Manager', href: '/dashboard/file-manager'),
      const SidebarItem(label: 'Databases', href: '/dashboard/databases'),
      const SidebarItem(label: 'Mail', href: '/dashboard/mail'),
      if (role == 'admin') ...[
        const SidebarItem(label: 'Servers', href: '/dashboard/servers'),
        const SidebarItem(label: 'Plans', href: '/dashboard/plans'),
        const SidebarItem(label: 'Jobs', href: '/dashboard/jobs'),
      ],
      const SidebarItem(label: 'Backups', href: '/dashboard/backups'),
    ];
  }

  String _normalizePath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }

    return path.isEmpty ? '/' : path;
  }
}
