import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  Map<String, String> _localErrors = {};

  @override
  void dispose() {
    for (final controller in [
      _email,
      _password,
      _password2,
      _name,
      _phone,
      _company,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localErrors = {});
    final cubit = context.read<AuthCubit>();
    if (!_isLogin && _password.text != _password2.text) {
      setState(() => _localErrors = {
            'password_confirmation': tr('passwordMismatch'),
          });
      return;
    }
    final ok = _isLogin
        ? await cubit.login(_email.text.trim(), _password.text)
        : await cubit.register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            company: _company.text.trim(),
            password: _password.text,
            passwordConfirmation: _password2.text,
          );
    if (!mounted || !ok) return;
    _leave();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final c = context.col;
    final tabs = [tr('tabLogin'), tr('tabRegister')];
    String? errorOf(String field) =>
        _localErrors[field] ?? auth.fieldErrors[field];

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, next) =>
          previous.submitting && !next.submitting && next.errorMessage != null,
      listener: (context, state) {
        showToast(context, state.errorMessage!, error: true);
      },
      child: AppScaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 34),
                const Center(child: LogoMark(size: 64, iconSize: 36)),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    tr('clientPortal'),
                    style: amiri(size: 17, color: c.text),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr('loginSub'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: c.stone),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: cardDeco(context, radius: 14),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: c.chipBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: List.generate(2, (i) {
                            final on = (_isLogin && i == 0) || (!_isLogin && i == 1);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isLogin = i == 0);
                                  context.read<AuthCubit>().clearFeedback();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: on ? c.surface : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: on
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: .08),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tabs[i],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: on ? c.text : c.stone,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_isLogin) ...[
                        AppField(
                          tr('email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          errorText: errorOf('email'),
                        ),
                        AppField(
                          tr('password'),
                          controller: _password,
                          obscure: true,
                          errorText: errorOf('password'),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            tr('forgotPassword'),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenMid,
                            ),
                          ),
                        ),
                      ] else ...[
                        AppField(
                          tr('fullName'),
                          controller: _name,
                          errorText: errorOf('name'),
                        ),
                        AppField(
                          tr('phone'),
                          controller: _phone,
                          hint: '05xxxxxxxx',
                          keyboardType: TextInputType.phone,
                          errorText: errorOf('phone'),
                        ),
                        AppField(
                          tr('company'),
                          controller: _company,
                          errorText: errorOf('company_name'),
                        ),
                        AppField(
                          tr('email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          errorText: errorOf('email'),
                        ),
                        AppField(
                          tr('password'),
                          controller: _password,
                          obscure: true,
                          errorText: errorOf('password'),
                        ),
                        AppField(
                          tr('passwordConfirm'),
                          controller: _password2,
                          obscure: true,
                          errorText: errorOf('password_confirmation'),
                        ),
                        const SizedBox(height: 4),
                      ],
                      AppButton(
                        _isLogin ? tr('doLogin') : tr('doRegister'),
                        loading: auth.submitting,
                        onTap: _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: _leave,
                    child: Text(
                      tr('continueGuest'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c.stone,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
