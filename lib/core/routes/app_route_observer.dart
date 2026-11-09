import 'package:flutter/widgets.dart';

/// Tracks the live route stack so code outside the widget tree (push
/// notification handlers, analytics) can ask where the user currently is.
///
/// Dialogs and bottom sheets are routes too but carry no name, so they are
/// skipped when resolving [currentRouteName].
class AppRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  /// Name of the topmost named route, or `null` when none is named.
  String? get currentRouteName {
    for (final route in _stack.reversed) {
      final name = route.settings.name;
      if (name != null) return name;
    }
    return null;
  }

  /// Whether a route called [name] is anywhere in the stack.
  bool isOpen(String name) => _stack.any((r) => r.settings.name == name);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute == null) {
      if (index >= 0) _stack.removeAt(index);
    } else if (index >= 0) {
      _stack[index] = newRoute;
    } else {
      _stack.add(newRoute);
    }
  }
}
