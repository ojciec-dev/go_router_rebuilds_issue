// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final logger = MyLogger();

const _useGoRouter = true;

/// This app demonstrates that using GoRouter(v13.2.0) with non-const widgets causes [build] method being called on
/// Widgets that are no longer visible. However, the same transitions but using standard Navigator API does not cause
/// unnecessary rebuilds.
///
/// There are 4 nested pages: home > pageA > pageB > pageC > pageD.
///
/// Steps to reproduce the issue:
/// 1. Set [_useGoRouter] to true and run the app
/// 2. Navigate from Home to pageD (via pageA, pageB and pageC)
/// 3. Observe the logs/snackbar and notice that [build] method of pageA and pageB gets called when we navigate to pageC
///    and pageD. At this point pageA and pageB are not visible, but still their [build] method is called.
///
/// 4. Change [_useGoRouter] to false and restart the app
/// 5. Again navigate from Home to pageD (via pageA, pageB and pageC)
/// 6. Notice that this time pageA and pageB are not unneccessarily rebuilt
void main() {
  if (_useGoRouter) {
    // This app uses GoRouter and demonstrates that pageB and pageC (which are not const) rebuild unnecessary when next
    // pages are displayed.
    runApp(const GoRouterApp());
  } else {
    // This app uses standard Navigator API and demonstrates that pushing the same pages does not causes any unneccessary rebuilds of previously displayed pages.
    runApp(const NavigatorApp());
  }
}

class GoRouterApp extends StatelessWidget {
  const GoRouterApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Launching GoRouter app that demonstrates unneccessary rebuilds of pageA and pageB.');
    return MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const GoRouterPage('home', dest: 'pageA'),
            routes: [
              GoRoute(
                path: 'pageA',
                name: 'pageA',
                // non-const on purpose to show that this page will get rebuilt even thos it won't be visible
                // ignore: prefer_const_constructors
                builder: (context, state) => GoRouterPage('pageA', dest: 'pageB'),
                routes: [
                  GoRoute(
                    path: 'pageB',
                    name: 'pageB',
                    // non-const on purpose
                    // ignore: prefer_const_constructors
                    builder: (context, state) => GoRouterPage('pageB', dest: 'pageC'),
                    routes: [
                      GoRoute(
                        path: 'pageC',
                        name: 'pageC',
                        builder: (context, state) => const GoRouterPage('pageC', dest: 'pageD'),
                        routes: [
                          GoRoute(
                            path: 'pageD',
                            name: 'pageD',
                            builder: (context, state) => const GoRouterPage('pageD'),
                          )
                        ],
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class GoRouterPage extends StatelessWidget {
  final String name;
  final String? dest;

  const GoRouterPage(this.name, {this.dest, super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageName: name,
      tag: 'GoRouterPage',
      child: ElevatedButton(
        onPressed: dest == null
            ? null
            : () {
                logger.reset();
                context.pushNamed(dest!);
              },
        child: Text('GoRouter.pushNamed: $dest'),
      ),
    );
  }
}

class NavigatorApp extends StatelessWidget {
  const NavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Launching Navigator app');
    return MaterialApp(
      home: NavigatorPage('/', destinations: const ['pageA', 'pageB', 'pageC', 'pageD']),
    );
  }
}

class NavigatorPage extends StatelessWidget {
  final String name;
  final List<String> destinations;

  // Removed 'const' on purpose to demonstrate Navigator works fine with non-const widgets.
  // ignore: prefer_const_constructors_in_immutables
  NavigatorPage(
    this.name, {
    this.destinations = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageName: name,
      tag: 'NavigatorPage',
      child: ElevatedButton(
        onPressed: destinations.isEmpty
            ? null
            : () {
                logger.reset();
                final dests = [...destinations];
                dests.removeAt(0);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) {
                    return NavigatorPage(destinations.first, destinations: dests);
                  },
                ));
              },
        child: Text(destinations.isEmpty ? '-' : 'Navigator.push: ${destinations.first}'),
      ),
    );
  }
}

/// Just an UI with AppBar and one button in the middle.
class BasePage extends StatelessWidget {
  final String pageName;
  final String tag;
  final Widget child;

  const BasePage({
    required this.pageName,
    required this.tag,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    logger.log('$tag [$pageName]', context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Page $pageName'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  logger.reset();
                  Navigator.of(context).pop();
                },
              )
            : null,
      ),
      body: Container(
        color: Colors.accents[pageName.codeUnitAt(pageName.length - 1) % Colors.accents.length],
        child: Center(
          child: child,
        ),
      ),
    );
  }
}

// Helper printing logs and showing snack bar when unwanted build() was detected.
class MyLogger {
  final List<String> logs = [];

  MyLogger();

  void log(String message, BuildContext context) async {
    // if [logs] is not empty it means that one of the previously displayed pages (that currently is invisble) just go rebuilt
    if (logs.isNotEmpty) {
      print('!! [ERROR] !! UNWANTED build() called for page: $message');
      WidgetsBinding.instance.addPostFrameCallback((_) => context.showUnwantedRebuildSnackBar(message));
      return;
    }

    print('[OK] build() called for page: $message');
    logs.add(message);
  }

  void reset() => logs.clear();
}

extension _BuildContextExt on BuildContext {
  /// Show styled 3s snackbar to tell which widget was unnecessarily rebuilt.
  void showUnwantedRebuildSnackBar(String rebuiltWidgetName) {
    if (!mounted) return;

    final textStyle = Theme.of(this).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
        );
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8.0),
                Text(
                  'UNWANTED REBUILD',
                  style: textStyle,
                ),
                const SizedBox(width: 8.0),
                const Icon(Icons.warning, color: Colors.white),
              ],
            ),
            const SizedBox(height: 8.0),
            Column(
              children: [
                Text(
                  'build() called for',
                  style: textStyle,
                ),
                Text(
                  rebuiltWidgetName,
                  style: textStyle?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade900,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      ),
    );
  }
}
