import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/models.dart';

void main() {
  test('themeMode par défaut = auto', () {
    const s = AppSettings();
    expect(s.themeMode, AppThemeChoice.auto);
  });

  test('copyWith change themeMode sans toucher au reste', () {
    const s = AppSettings(serverUrl: 'ws://x', myLat: 1.0);
    final s2 = s.copyWith(themeMode: AppThemeChoice.dark);
    expect(s2.themeMode, AppThemeChoice.dark);
    expect(s2.serverUrl, 'ws://x');
    expect(s2.myLat, 1.0);
  });
}
