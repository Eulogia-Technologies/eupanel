import 'package:flint_ui/flint_ui.dart';
import 'package:universal_web/web.dart' as web;

import '../services/auth_client.dart';

class LoginPage extends FlintComponent {
  final Map<String, dynamic> props;

  LoginPage(this.props);

  final _form = useForm({
    'email': '',
    'password': '',
  });
  String? _error;

  @override
  FlintNode build() {
    return Container(
      className: 'auth-shell',
      dartStyle: const DartStyle(
        minHeight: SizeValue('100vh'),
        display: Display.grid,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.center,
        padding: EdgeInsets.symmetric(vertical: 36, horizontal: 18),
        gradient: Gradients.softPanel,
      ),
      children: [
        Panel(
          className: 'auth-panel',
          dartStyle: const DartStyle(
            width: SizeValue.full,
            maxWidth: 460,
            display: Display.grid,
            gap: 22,
            padding: EdgeInsets.all(34),
            radius: 28,
            background: Color.rgba(255, 255, 255, 0.85),
            backdropFilter: 'blur(20px)',
            border: Border.all(color: Color.rgba(148, 163, 184, 0.25)),
            shadow: Shadow(
              x: 0,
              y: 32,
              blur: 80,
              spread: -20,
              color: Color.rgba(15, 23, 42, 0.22),
            ),
          ),
          children: [
            Head(
              title: 'EuPanel Logins',
              tags: [
                Head.meta(
                  name: 'description',
                  content:
                      'Sign in to EuPanel to manage hosting, DNS, SSL, databases, and provisioning.',
                ),
              ],
            ),
            Container(
              dartStyle: const DartStyle(
                display: Display.flex,
                alignItems: AlignItems.center,
                gap: 14,
              ),
              children: [
                Container(
                  className: 'brand-mark',
                  dartStyle: const DartStyle(
                    width: 44,
                    height: 44,
                    display: Display.flex,
                    alignItems: AlignItems.center,
                    justifyContent: JustifyContent.center,
                    radius: 16,
                    gradient: Gradients.ocean,
                    color: Colors.white,
                    fontWeight: 800,
                    shadow: Shadow(
                      x: 0,
                      y: 16,
                      blur: 30,
                      spread: -14,
                      color: Color.rgba(37, 99, 235, 0.9),
                    ),
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    hover: DartStyle(
                      transform: 'scale(1.08)',
                      shadow: Shadow(
                        x: 0,
                        y: 20,
                        blur: 34,
                        spread: -10,
                        color: Color.rgba(37, 99, 235, 0.95),
                      ),
                    ),
                    md: DartStyle(
                      width: 52,
                      height: 52,
                    ),
                  ),
                  child: Text('EP'),
                ),
                Container(
                  dartStyle: const DartStyle(
                    display: Display.grid,
                    gap: 2,
                  ),
                  children: [
                    Text.strong(
                      'EuPanel',
                      dartStyle: const DartStyle(
                        color: Colors.slate900,
                        fontSize: 24,
                        lineHeight: 1.05,
                      ),
                    ),
                    Text.small(
                      'Control center',
                      dartStyle: const DartStyle(
                        color: Colors.slate500,
                        fontSize: 13,
                        fontWeight: 700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              dartStyle: const DartStyle(
                display: Display.grid,
                gap: 8,
              ),
              children: [
                Text.h1(
                  'Welcome back',
                  dartStyle: const DartStyle(
                    margin: EdgeInsets.all(0),
                    color: Color('#111827'),
                    fontSize: 32,
                    lineHeight: 1.1,
                    fontWeight: 800,
                  ),
                ),
                Text.p(
                  'Sign in to manage hosting, DNS, SSL, databases, and provisioning from one workspace.',
                  className: 'muted',
                  dartStyle: const DartStyle(
                    margin: EdgeInsets.all(0),
                    color: Colors.slate500,
                    fontSize: 15,
                    lineHeight: 1.6,
                  ),
                ),
              ],
            ),
            Text.p(
              'Secure admin access',
              dartStyle: const DartStyle(
                display: Display.inlineFlex,
                width: SizeValue('fit-content'),
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                radius: 999,
                background: Colors.cyan50,
                color: Colors.cyan700,
                fontSize: 12,
                fontWeight: 800,
                lineHeight: 1,
                margin: EdgeInsets.all(0),
              ),
            ),
            Form(
                className: 'auth-form',
                onSubmit: _handleSubmit,
                dartStyle: const DartStyle(
                  display: Display.grid,
                  gap: 16,
                ),
                children: [
                  TextField(
                    label: 'Email',
                    name: 'email',
                    controller: _form.controller('email'),
                    type: 'email',
                    placeholder: 'admin@example.com',
                    required: true,
                    disabled: _form.processing,
                    inputStyle: const {
                      'border-radius': '14px',
                      'padding': '13px 14px',
                      'border': '1px solid #d9e2ef',
                      'background': '#f8fafc',
                      'font-size': '15px',
                    },
                  ),
                  TextField(
                    label: 'Password',
                    name: 'password',
                    controller: _form.controller('password'),
                    type: 'password',
                    placeholder: 'Password',
                    required: true,
                    disabled: _form.processing,
                    inputStyle: const {
                      'border-radius': '14px',
                      'padding': '13px 14px',
                      'border': '1px solid #d9e2ef',
                      'background': '#f8fafc',
                      'font-size': '15px',
                    },
                  ),
                  if (_error != null)
                    Text.p(
                      _error!,
                      className: 'auth-error',
                      dartStyle: const DartStyle(
                        padding:
                            EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                        margin: EdgeInsets.all(0),
                        radius: 14,
                        background: Colors.rose50,
                        border: Border.all(color: Colors.rose200),
                        color: Colors.rose700,
                        fontSize: 13,
                        lineHeight: 1.45,
                      ),
                    ),
                  Button(
                    className: 'primary-button',
                    props: const {'type': 'submit'},
                    loading: _form.processing,
                    disabled: _form.processing,
                    dartStyle: const DartStyle(
                      width: SizeValue.full,
                      minHeight: 48,
                      radius: 14,
                      fontSize: 15,
                      fontWeight: 800,
                      gradient: Gradients.sky,
                      border: Border.all(color: Color.rgba(37, 99, 235, 0.3)),
                      shadow: Shadow(
                        x: 0,
                        y: 12,
                        blur: 24,
                        spread: -12,
                        color: Color.rgba(37, 99, 235, 0.5),
                      ),
                      transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                      hover: DartStyle(
                        transform: 'translateY(-2px)',
                        shadow: Shadow(
                          x: 0,
                          y: 16,
                          blur: 28,
                          spread: -10,
                          color: Color.rgba(37, 99, 235, 0.6),
                        ),
                      ),
                    ),
                    child: Text(_form.processing ? 'Signing in...' : 'Sign in'),
                  ),
                ]),
            Button(
              className: 'secondary-button full-button',
              child: Text('Use demo admin'),
              disabled: _form.processing,
              dartStyle: const DartStyle(
                width: SizeValue.full,
                minHeight: 46,
                radius: 14,
                background: Colors.white,
                border: Border.all(color: Color('#d9e2ef')),
                color: Colors.slate700,
                fontWeight: 800,
                transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                hover: DartStyle(
                  background: '#f8fafc',
                  color: Colors.slate900,
                  border: Border.all(color: Color('#cbd5e1')),
                  transform: 'translateY(-1px)',
                ),
              ),
              onPressed: (_) {
                _fillDemoCredentials(
                  email: 'admin@eupanel.local',
                  password: 'Admin@12345',
                );
              },
            ),
            if (props['demoSeedEnabled'] == true)
              Link(
                href: '/auth/seed-default-users',
                className: 'text-link',
                dartStyle: const DartStyle(
                  color: Colors.blue600,
                  textAlign: TextAlign.center,
                  fontSize: 14,
                  fontWeight: 800,
                ),
                child: 'Prepare demo users',
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSubmit(Object event) async {
    if (event is web.Event) {
      event.preventDefault();
    }

    final email = _form.string('email').trim();
    final password = _form.string('password');

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email and password are required.';
      });
      return;
    }

    final submit = _form.submit<AuthSession>(
      (_) {
        return AuthClient(authBase: _authBase).login(
          email: email,
          password: password,
        );
      },
      onSuccess: (session) {
        navigation.assign(session.dashboardPath);
      },
      onError: (error) {
        setState(() {
          _error = _friendlyError(error);
        });
      },
    );
    setState(() {
      _error = null;
    });
    await submit;
    setState(() {});
  }

  String get _authBase {
    final value = props['authBase']?.toString();
    if (value != null && value.isNotEmpty) return value;

    final apiBase = props['apiBase']?.toString();
    if (apiBase != null && apiBase.isNotEmpty && apiBase != '/api') {
      return '$apiBase/auth';
    }

    return '/auth';
  }

  void _fillDemoCredentials({
    required String email,
    required String password,
  }) {
    _form.setField('email', email);
    _form.setField('password', password);
    setState(() {});
  }

  String _friendlyError(Object error) {
    if (error is web.ProgressEvent) {
      return 'Could not sign in. Check the credentials and try again.';
    }

    final message = error.toString();
    if (message.contains('XMLHttpRequest')) {
      return 'Could not reach the EuPanel auth server.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}
