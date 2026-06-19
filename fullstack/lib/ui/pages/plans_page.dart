import 'package:flint_ui/flint_ui.dart';

import '../components/plans_view.dart';

class PlansPage extends StatelessComponent {
  PlansPage({
    required this.role,
    required this.plans,
  });

  final String role;
  final ResourceController<List<FlintModelRecord>> plans;

  @override
  View build() {
    return PlansView(role: role, plans: plans);
  }
}
