import 'package:flint_ui/flint_ui.dart';

import '../components/websites_domains_view.dart';

class WebsitesDomainsPage extends StatelessComponent {
  WebsitesDomainsPage({
    required this.role,
    required this.subscriptions,
  });

  final String role;
  final ResourceController<List<FlintModelRecord>> subscriptions;

  @override
  View build() {
    return WebsitesDomainsView(
      role: role,
      subscriptions: subscriptions,
    );
  }
}
