import 'package:flint_ui/flint_ui.dart';

import 'component_registry.dart';
import 'middleware/auth_middleware.dart';

void main() {
  createFlintApp(
    '#app',
    registry: componentRegistry,
    middlewares: [requireAuth],
  );
}
