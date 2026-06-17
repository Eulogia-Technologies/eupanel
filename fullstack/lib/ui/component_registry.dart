import 'package:flint_ui/flint_ui.dart';

import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';

final componentRegistry = FlintComponentRegistry({
  'Dashboard': (props) => DashboardPage(props),
  'Login': (props) => LoginPage(props),
});
