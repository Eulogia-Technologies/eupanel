import 'dart:math';

class PasswordGeneratorService {
  static const _lower = 'abcdefghijkmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const _digits = '23456789';
  static const _symbols = '!@#%*-_=+?';

  final Random _random = Random.secure();

  String generate({int length = 18}) {
    final safeLength = length < 12 ? 12 : length;
    final all = _lower + _upper + _digits + _symbols;
    final chars = <String>[
      _pick(_lower),
      _pick(_upper),
      _pick(_digits),
      _pick(_symbols),
      for (var i = 4; i < safeLength; i++) _pick(all),
    ];

    for (var i = chars.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }

    return chars.join();
  }

  String _pick(String chars) => chars[_random.nextInt(chars.length)];
}
