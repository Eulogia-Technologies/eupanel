import 'package:flint_ui/flint_ui.dart';
import 'package:backend/ui/pages/dashboard_page.dart';


void main() {
  createFlintApp(
    '#app',
    pages: {'Dashboard': (props) => DashboardPage(props)},
  );
}
