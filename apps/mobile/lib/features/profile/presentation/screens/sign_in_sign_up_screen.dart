import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../core/widgets/rahati_logo_mark.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/repositories/auth_repository.dart";
import "../providers/auth_providers.dart";

/// SCR-030 — Sign In / Sign Up (optional) (US-05.1, FR-USR-01).
///
/// Pushed from SCR-020's guest-state "Se connecter" button. Email +
/// password only for this pass — see [AuthRepository]'s own doc comment
/// for why OTP/phone are deferred. "Continuer sans compte" is always
/// available and never de-emphasized (equal `bodyMedium` weight to the
/// primary action), per the wireframe's own accessibility requirement —
/// FR-USR-01 makes registration optional, not required.
class SignInSignUpScreen extends ConsumerStatefulWidget {
  const SignInSignUpScreen({super.key});

  @override
  ConsumerState<SignInSignUpScreen> createState() =>
      _SignInSignUpScreenState();
}

class _SignInSignUpScreenState extends ConsumerState<SignInSignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final AuthRepository repository = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await repository.signUpWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await repository.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) context.pop();
    } on AuthNotConfiguredFailure {
      if (mounted) {
        setState(() => _errorMessage = l10n.signInNotConfiguredError);
      }
    } on AuthRepositoryFailure {
      // Deliberately generic — the underlying failure's own `message` is
      // an internal, unlocalized string (see `signInGenericError`'s own
      // ARB description), never shown to the user directly.
      if (mounted) setState(() => _errorMessage = l10n.signInGenericError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signInAppBarTitle),
        leading: CloseButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RahatiSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: RahatiLogoMark(
                  color: colorScheme.primary,
                  onColor: colorScheme.onPrimary,
                  size: 56,
                ),
              ),
              const SizedBox(height: RahatiSpacing.space6),
              SegmentedButton<bool>(
                segments: <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.signInTabLabel),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.signUpTabLabel),
                  ),
                ],
                selected: <bool>{_isSignUp},
                onSelectionChanged: (selection) {
                  setState(() {
                    _isSignUp = selection.first;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: RahatiSpacing.space6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.signInEmailLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: RahatiSpacing.space4),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.signInPasswordLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: RahatiSpacing.space4),
                Container(
                  padding: const EdgeInsets.all(RahatiSpacing.space3),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // label: + ExcludeSemantics (US-06.4 finding, same class
                  // as place_detail_sheet.dart's _DetailStatusLine) — a
                  // bare `liveRegion: true` here risked the child Text's
                  // own implicit semantics node doubling up alongside this
                  // explicit label.
                  child: Semantics(
                    liveRegion: true,
                    label: _errorMessage!,
                    child: ExcludeSemantics(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: RahatiSpacing.space6),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                // While submitting, the child has no Text — a bare
                // CircularProgressIndicator carries no semantics label of
                // its own, so the button lost its accessible name entirely
                // (WCAG 4.1.2), the identical pattern
                // submit_review_screen.dart's own "Publier" button had
                // (US-06.4 finding F18) before that pass explicitly flagged
                // this file as having the same unfixed gap. Wrapping just
                // the spinner keeps the button's name stable across both
                // states without touching FilledButton's own
                // button-role/enabled semantics.
                child: _submitting
                    ? Semantics(
                        label: _isSignUp
                            ? l10n.signUpSubmitButton
                            : l10n.signInSubmitButton,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(
                        _isSignUp
                            ? l10n.signUpSubmitButton
                            : l10n.signInSubmitButton,
                      ),
              ),
              const SizedBox(height: RahatiSpacing.space4),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  l10n.signInContinueAsGuestButton,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
