import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'auth/auth_controller.dart';
import 'router.dart';
import 'theme/stark_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Real paths (/vehicles) instead of /#/vehicles. The host must serve index.html for every
  // path (Netlify rewrite in Phase 6).
  usePathUrlStrategy();
  await Hive.initFlutter();
  final sessionBox = await Hive.openBox<dynamic>('session');

  runApp(
    ProviderScope(
      overrides: [sessionBoxProvider.overrideWithValue(sessionBox)],
      child: const StarkVmsApp(),
    ),
  );
}

class StarkVmsApp extends ConsumerWidget {
  const StarkVmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadApp.router(
      title: 'Stark VMS',
      debugShowCheckedModeBanner: false,
      // Single light theme by choice (DESIGN.md): the same theme for light and dark system settings.
      theme: starkTheme(),
      darkTheme: starkTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
