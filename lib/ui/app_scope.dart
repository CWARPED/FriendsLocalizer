import 'package:flutter/widgets.dart';
import 'app_repository.dart';

/// Expose le [AppRepository] à tout l'arbre (au-dessus du MaterialApp).
class AppScope extends InheritedWidget {
  final AppRepository repository;
  const AppScope({super.key, required this.repository, required super.child});

  static AppRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope introuvable dans le contexte');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.repository != repository;
}
