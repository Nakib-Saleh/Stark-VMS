import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'auth/auth_controller.dart';
import 'network/server_wake.dart';
import 'router.dart';
import 'theme/stark_theme.dart';
import 'widgets/server_wake_notice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Real paths (/vehicles) instead of /#/vehicles. The host must serve index.html for every
  // path (`web/_redirects` for Netlify).
  usePathUrlStrategy();
  await Hive.initFlutter();
  final sessionBox = await Hive.openBox<dynamic>('session');

  final container = ProviderContainer(overrides: [sessionBoxProvider.overrideWithValue(sessionBox)]);
  // Start waking the free-tier API now, while the visitor reads the landing page. Here rather
  // than in the widget so widget tests don't make network calls.
  container.read(serverWakeProvider.notifier).probe();

  runApp(UncontrolledProviderScope(container: container, child: const StarkVmsApp()));
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
      // The waking notice floats over every page.
      builder: (context, child) => Stack(children: [?child, const ServerWakeNotice()]),
    );
  }
}
