import 'package:flint_ui/flint_ui.dart';

const eupanelSession = AuthSessionManager(
  tokenKey: 'eupanel.token',
  userKey: 'eupanel.user',
);

void requireAuth(FlintPageContext context) {
  if (context.page.component != 'Dashboard') return;
  if (eupanelSession.isLoggedIn) return;

  navigation.redirect('/login');
  context.stop();
}
