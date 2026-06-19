import 'package:flint_ui/flint_ui.dart';

import '../components/subscriptions_view.dart';

class SubscriptionsPage extends StatelessComponent {
  SubscriptionsPage({
    required this.role,
    required this.plans,
    required this.subscriptions,
  });

  final String role;
  final ResourceController<List<FlintModelRecord>> plans;
  final ResourceController<List<FlintModelRecord>> subscriptions;

  @override
  View build() {
    return SubscriptionsView(
      role: role,
      plans: plans,
      subscriptions: subscriptions,
    );
  }
}
