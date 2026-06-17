import 'package:flint_ui/flint_ui.dart';
import 'package:backend/ui/pages/login_page.dart';


void main() {
  createFlintApp(
    '#app',
    pages: {'Login': (props) => LoginPage(props)},
  );
}
