import 'package:flint_ui/flint_ui.dart';

class EuPanelDashboardSidebar extends FlintComponent {
  EuPanelDashboardSidebar({
    required this.role,
  });

  final String role;

  @override
  FlintNode build() {
    final activePath = _normalizePath(currentUri.path);

    return Column(
      className: 'sidebar',
      dartStyle: const DartStyle(
        flex: Flex.fill(),
        minHeight: 0,
      ),
      children: [
        Sidebar(
          items: _items,
          activePath: activePath,
          style: const {
            'width': '100%',
          },
        ),
        Link(
          href: '/login',
          className: 'sidebar-link muted-link',
          style: const {
            'margin-top': 'auto',
          },
          child: 'Sign in',
        ),
      ],
    );
  }

  List<SidebarItem> get _items {
    return [
      const SidebarItem(label: 'Overview', href: '/dashboard'),
      const SidebarItem(label: 'Websites', href: '/dashboard/websites-domains'),
      const SidebarItem(label: 'Domains', href: '/dashboard/domains'),
      const SidebarItem(label: 'DNS', href: '/dashboard/dns-settings'),
      const SidebarItem(label: 'Databases', href: '/dashboard/databases'),
      const SidebarItem(label: 'SSL', href: '/dashboard/ssl-certificates'),
      const SidebarItem(label: 'Backups', href: '/dashboard/backups'),
      if (role == 'admin')
        const SidebarItem(label: 'Servers', href: '/dashboard/admin/servers'),
      if (role == 'admin')
        const SidebarItem(label: 'Jobs', href: '/dashboard/admin/jobs'),
    ];
  }

  String _normalizePath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }

    return path.isEmpty ? '/' : path;
  }
}
