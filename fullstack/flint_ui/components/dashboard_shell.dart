import 'package:flint_ui/flint_ui.dart';

class EuPanelDashboardShell extends FlintElement {
  EuPanelDashboardShell({
    Object? brand,
    Object? sidebar,
    Object? topbar,
    Object? child,
    List<Object?> children = const [],
    String? className,
  }) : super(
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
            if (sidebar != null)
              FlintElement(
                'aside',
                props: const {
                  'style': {
                    'align-self': 'start',
                    'background': '#ffffff',
                    'border-right': '1px solid #e4e7ec',
                    'display': 'flex',
                    'flex-direction': 'column',
                    'height': '100vh',
                    'overflow-y': 'auto',
                    'position': 'sticky',
                    'top': 0,
                  },
                },
                children: [
                  if (brand != null)
                    FlintElement(
                      'div',
                      props: const {
                        'style': {
                          'padding': '20px',
                          'border-bottom': '1px solid #e4e7ec',
                          'flex': '0 0 auto',
                          'font-weight': 700,
                        },
                      },
                      children: normalizeChildren(brand, const []),
                    ),
                  toFlintNode(sidebar),
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
