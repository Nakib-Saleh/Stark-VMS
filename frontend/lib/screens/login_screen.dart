import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../auth/auth_controller.dart';
import '../theme/stark_tokens.dart';
import '../widgets/stark_page.dart';
import '../widgets/brand.dart';
import '../widgets/number_plate.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.next});

  /// Where to go after signing in (an app path the user was trying to open).
  final String? next;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  String? _error;
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _error = null;
      _usernameError = _username.text.trim().isEmpty ? 'Enter your username' : null;
      _passwordError = _password.text.isEmpty ? 'Enter your password' : null;
    });
    if (_usernameError != null) return _usernameFocus.requestFocus();
    if (_passwordError != null) return _passwordFocus.requestFocus();

    setState(() => _busy = true);
    final error = await ref.read(authProvider.notifier).signIn(_username.text, _password.text);
    if (!mounted) return;
    if (error == null) {
      TextInput.finishAutofillContext();
      context.go(safeNext(widget.next));
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
    _password.selection = TextSelection(baseOffset: 0, extentOffset: _password.text.length);
    _passwordFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(authProvider.select((s) => s.notice));
    final wide = MediaQuery.sizeOf(context).width >= 820;

    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!wide) ...[
                  const Brand(onNavy: false),
                  const SizedBox(height: 32),
                ],
                Semantics(header: true, child: Text('Sign in', style: StarkText.display(30, weight: FontWeight.w700, width: 112, color: StarkColors.ink))),
                const SizedBox(height: 6),
                Text('Use the account your fleet manager gave you.', style: StarkText.body(15, color: StarkColors.muted)),
                const SizedBox(height: 22),
                if (notice != null && _error == null) ...[
                  _Banner(text: notice, tone: _Tone.info),
                  const SizedBox(height: 16),
                ],
                if (_error != null) ...[
                  _Banner(text: _error!, tone: _Tone.error),
                  const SizedBox(height: 16),
                ],
                _Field(
                  label: 'Username',
                  error: _usernameError,
                  child: ShadInput(
                    controller: _username,
                    focusNode: _usernameFocus,
                    autofocus: true,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    enabled: !_busy,
                    onChanged: (_) {
                      if (_usernameError != null) setState(() => _usernameError = null);
                    },
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'Password',
                  error: _passwordError,
                  child: ShadInput(
                    controller: _password,
                    focusNode: _passwordFocus,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    enabled: !_busy,
                    onChanged: (_) {
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 22),
                ShadButton(
                  onPressed: _busy ? null : _submit,
                  height: 42,
                  leading: _busy
                      ? const SizedBox.square(
                          dimension: 14,
                          child: Spinner(),
                        )
                      : null,
                  child: Text(_busy ? 'Signing in' : 'Sign in'),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ShadButton.link(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go('/'),
                    leading: const Icon(LucideIcons.chevronLeft, size: 18),
                    child: const Text('Back to the home page'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return StarkPage(

      child: wide
          ? Row(children: [
              const Expanded(child: _NavySide()),
              Expanded(child: form),
            ])
          : form,
    );
  }
}

/// Only allow returning to one of our own app paths (never another site: open-redirect guard).
String safeNext(String? next) {
  if (next == null || !next.startsWith('/') || next.startsWith('//') || next.startsWith('/login')) {
    return '/vehicles';
  }
  return next;
}

class _NavySide extends StatelessWidget {
  const _NavySide();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StarkColors.navy,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Brand(onNavy: true),
            const Spacer(),
            const Center(
              child: SizedBox(width: 420, child: NumberPlate('CTG-METRO-GHA-13-9003', size: PlateSize.xl)),
            ),
            const SizedBox(height: 18),
            Center(child: Text('Fleet register for Stark Group staff.', style: StarkText.body(15, color: StarkColors.onNavyMuted))),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, this.error});

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StarkText.body(14, weight: FontWeight.w600, color: StarkColors.ink)),
        const SizedBox(height: 6),
        child,
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: StarkText.body(13, weight: FontWeight.w500, color: StarkColors.red)),
        ],
      ],
    );
  }
}

enum _Tone { info, error }

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.tone});

  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == _Tone.error;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isError ? StarkColors.errorTint : StarkColors.paper,
          borderRadius: BorderRadius.circular(StarkRadius.control),
          border: Border.all(color: isError ? StarkColors.errorBorder : StarkColors.line),
        ),
        child: Text(text, style: StarkText.body(14, color: isError ? StarkColors.red : StarkColors.ink)),
      ),
    );
  }
}
