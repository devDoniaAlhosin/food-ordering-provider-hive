import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Provider/auth_provider.dart';
import '../../extensions/string_validators.dart';
import '../../extensions/text_form_field_extensions.dart';
import '../../theme/app_theme.dart';

/// Noon-style auth: Sign in and Create account as tabs on one screen.
class AuthTabsScreen extends StatefulWidget {
  const AuthTabsScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AuthTabsScreen> createState() => _AuthTabsScreenState();
}

class _AuthTabsScreenState extends State<AuthTabsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  final _name = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureRegister = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _name.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _goToApp() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.login(
      email: _loginEmail.text,
      password: _loginPassword.text,
    );
    if (!mounted) return;
    if (ok) {
      _goToApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Login failed')),
      );
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.register(
      email: _registerEmail.text,
      password: _registerPassword.text,
      displayName: _name.text,
    );
    if (!mounted) return;
    if (ok) {
      _goToApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final theme = Theme.of(context);

    // If auth flips while this route is still open, clear it so Menu shows.
    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToApp());
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE8D6), AppTheme.cream],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Food Cart',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in or create your account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Noon-style segmented tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.ink.withValues(alpha: 0.7),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Sign in'),
                      Tab(text: 'Create account'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _AuthCard(
                      child: Form(
                        key: _loginFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextFormField.email(controller: _loginEmail),
                            const SizedBox(height: 14),
                            AppTextFormField.password(
                              controller: _loginPassword,
                              obscureText: _obscureLogin,
                              onToggleVisibility: () {
                                setState(() => _obscureLogin = !_obscureLogin);
                              },
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: auth.isBusy ? null : _login,
                              child: auth.isBusy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: auth.isBusy
                                  ? null
                                  : () => _tabs.animateTo(1),
                              child: const Text(
                                'New here? Create an account',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _AuthCard(
                      child: Form(
                        key: _registerFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextFormField.fullName(controller: _name),
                            const SizedBox(height: 14),
                            AppTextFormField.email(controller: _registerEmail),
                            const SizedBox(height: 14),
                            AppTextFormField.password(
                              controller: _registerPassword,
                              obscureText: _obscureRegister,
                              onToggleVisibility: () {
                                setState(
                                  () => _obscureRegister = !_obscureRegister,
                                );
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            AppTextFormField.password(
                              controller: _confirmPassword,
                              labelText: 'Confirm password',
                              obscureText: _obscureConfirm,
                              onToggleVisibility: () {
                                setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                );
                              },
                              validator: (value) {
                                final base = value.passwordValidator();
                                if (base != null) return base;
                                if (value != _registerPassword.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: auth.isBusy ? null : _register,
                              child: auth.isBusy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Create account'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: auth.isBusy
                                  ? null
                                  : () => _tabs.animateTo(0),
                              child: const Text(
                                'Already have an account? Sign in',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
