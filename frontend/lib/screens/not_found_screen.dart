import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../auth/auth_controller.dart';
import '../theme/stark_tokens.dart';
import '../widgets/stark_page.dart';
import '../widgets/brand.dart';

class NotFoundScreen extends ConsumerWidget {
  const NotFoundScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((s) => s.isSignedIn));
    return StarkPage(

      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Brand(onNavy: false),
              const SizedBox(height: 32),
              Semantics(
                header: true,
                child: Text("That page doesn't exist", style: StarkText.display(28, weight: FontWeight.w700, width: 112, color: StarkColors.ink)),
              ),
              const SizedBox(height: 8),
              Text('There is nothing at $path. Check the address, or go back to where you started.',
                  style: StarkText.body(15, color: StarkColors.muted)),
              const SizedBox(height: 24),
              ShadButton(
                onPressed: () => context.go(signedIn ? '/vehicles' : '/'),
                child: Text(signedIn ? 'Go to vehicles' : 'Go to the home page'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
