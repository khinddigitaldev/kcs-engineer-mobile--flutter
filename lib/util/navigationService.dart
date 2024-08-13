import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  navigateTo(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  pop(value) {
    return navigatorKey.currentState?.pop(value);
  }

  goBack() {
    return navigatorKey.currentState?.pop();
  }

  popUntil(String desiredRoute) {
    return navigatorKey.currentState?.popUntil((route) {
      return route.settings.name == desiredRoute;
    });
  }

  pushNamedAndRemoveUntil(route, popToInitial) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      route,
      (Route<dynamic> route) => popToInitial,
    );
  }

  pushNamedAndRemoveOthers() {
    navigatorKey.currentState
        ?.pushReplacementNamed('home', arguments: [0, null]);
  }

  static Future<void> pushReplacementNamed(String routeName) async {
    await navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  BuildContext getNavigationContext() {
    return navigatorKey.currentState!.context;
  }
}

class RestartWidget extends StatefulWidget {
  RestartWidget();

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: new Container(),
    );
  }
}
