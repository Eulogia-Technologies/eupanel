import 'package:backend/models/subscription_model.dart';
import 'package:backend/models/user_model.dart';
import 'package:flint_dart/flint_dart.dart';

class HostingUsernameService {
  Future<String> generateFromDomain(String domain) async {
    final base = _baseFromDomain(domain);

    for (var counter = 0; counter <= 999; counter++) {
      final suffix = counter == 0 ? '' : counter.toString().padLeft(3, '0');
      final candidate = _fit('$base$suffix');

      if (await _isAvailable(candidate)) {
        return candidate;
      }
    }

    throw Exception('Could not generate a unique hosting username for $domain');
  }

  String _baseFromDomain(String domain) {
    final clean = domain
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    final withPrefix =
        clean.isEmpty || RegExp(r'^[0-9]').hasMatch(clean) ? 'eu$clean' : clean;

    return _fit(withPrefix.length < 3 ? '${withPrefix}site' : withPrefix);
  }

  String _fit(String value) {
    const maxLinuxUsernameLength = 32;
    if (value.length <= maxLinuxUsernameLength) return value;
    return value.substring(0, maxLinuxUsernameLength);
  }

  Future<bool> _isAvailable(String username) async {
    final users = await User().whereSimple('username', username);
    if (users.isNotEmpty) return false;

    final panelUsers = await Subscription().whereSimple(
      'panel_username',
      username,
    );
    if (panelUsers.isNotEmpty) return false;

    final systemUsers = await Subscription().whereSimple(
      'system_username',
      username,
    );
    return systemUsers.isEmpty;
  }
}
