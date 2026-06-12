import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/ui/models.dart';
import 'package:friends_localizer/ui/real_repository.dart';
import 'package:friends_localizer/ui/store.dart';

void main() {
  test('themeMode survit à un rechargement', () async {
    final store = MemoryStore();
    final repo = await RealRepository.load(store);
    repo.updateSettings(
        repo.settings.copyWith(themeMode: AppThemeChoice.dark));

    final repo2 = await RealRepository.load(store);
    expect(repo2.settings.themeMode, AppThemeChoice.dark);
  });
}
