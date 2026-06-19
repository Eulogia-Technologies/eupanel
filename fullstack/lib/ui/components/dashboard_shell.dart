import 'package:flint_ui/flint_ui.dart';

import 'dashboard_sidebar.dart';

class EuPanelDashboardShell extends StatelessComponent {
  EuPanelDashboardShell({
    required this.role,
    Object? topbar,
    Object? child,
    this.children = const [],
    this.className,
  })  : topbar = topbar,
        child = child;

  final String role;
  final Object? topbar;
  final Object? child;
  final List<Object?> children;
  final String? className;

  @override
  View build() {
    return FlintElement(
      'div',
      props: mergeComponentProps(
        const {},
        className: className,
        defaultStyle: const {
          'display': 'grid',
          'grid-template-columns': '280px minmax(0, 1fr)',
          'min-height': '100vh',
          'background': '#f8fafc',
          'color': '#101828',
        },
      ),
      children: [
        FlintElement(
          'aside',
          props: const {
            'style': {
              'align-self': 'start',
              'background': '#090d16',
              'border-right': '1px solid rgba(255, 255, 255, 0.08)',
              'box-shadow': '4px 0 24px rgba(0, 0, 0, 0.15)',
              'display': 'flex',
              'flex-direction': 'column',
              'height': '100vh',
              'overflow-y': 'auto',
              'position': 'sticky',
              'top': 0,
            },
          },
          children: [
            FlintElement(
              'div',
              props: const {
                'style': {
                  'padding': '24px 20px',
                  'border-bottom': '1px solid rgba(255, 255, 255, 0.08)',
                  'flex': '0 0 auto',
                  'font-weight': 700,
                },
              },
              children: [toFlintNode(_brand())],
            ),
            toFlintNode(EuPanelDashboardSidebar(role: role)),
          ],
        ),
        FlintElement(
          'div',
          props: const {
            'style': {
              'display': 'grid',
              'grid-template-rows': 'auto minmax(0, 1fr)',
              'min-width': 0,
            },
          },
          children: [
            if (topbar != null) toFlintNode(topbar),
            FlintElement(
              'main',
              props: const {
                'style': {
                  'min-width': 0,
                  'padding': '24px',
                },
              },
              children: normalizeChildren(child, children),
            ),
          ],
        ),
      ],
    );
  }

  View _brand() {
    return Row(
      dartStyle: const DartStyle(
        alignItems: AlignItems.center,
        gap: 12,
      ),
      children: [
        Container(
          dartStyle: const DartStyle(
            display: Display.flex,
            alignItems: AlignItems.center,
            justifyContent: JustifyContent.center,
            width: 40,
            height: 40,
            radius: 12,
            background: 'linear-gradient(135deg, #06b6d4, #2563eb)',
            color: '#ffffff',
            fontWeight: 800,
            fontSize: 16,
            shadow: '0 0 16px rgba(6, 182, 212, 0.45)',
          ),
          child: Text('EP'),
        ),
        Column(
          dartStyle: const DartStyle(
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: 2,
          ),
          children: [
            Text.strong(
              'EuPanel',
              dartStyle: const DartStyle(
                color: '#ffffff',
                fontWeight: 800,
                fontSize: 16,
              ),
            ),
            Text.span(
              'Hosting control node',
              dartStyle: const DartStyle(
                color: '#64748b',
                fontSize: 11,
                fontWeight: 600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
