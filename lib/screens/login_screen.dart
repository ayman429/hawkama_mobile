import 'package:flutter/material.dart';

import '../api/errors.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../state/auth_store.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _busy = false;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();

  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    for (final c in [
      _email, _password, _password2, _name, _phone, _company
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _fieldErrors = {};
    });
    try {
      if (_isLogin) {
        await AuthStore.instance.login(_email.text.trim(), _password.text);
      } else {
        if (_password.text != _password2.text) {
          setState(() => _fieldErrors = {
                'password_confirmation': tr('passwordMismatch')
              });
          return;
        }
        await AuthStore.instance.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          company: _company.text.trim(),
          password: _password.text,
          passwordConfirmation: _password2.text,
        );
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainShell()), (r) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = {
          for (final e2 in e.fieldErrors.entries) e2.key: e2.value.first,
        };
      });
      showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final tabs = [tr('tabLogin'), tr('tabRegister')];
    return Scaffold(
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
                child: Text(tr('clientPortal'),
                    style: amiri(size: 17, color: c.text)),
              ),
              const SizedBox(height: 6),
              Text(tr('loginSub'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: c.stone)),
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
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: List.generate(2, (i) {
                          final on =
                              (_isLogin && i == 0) || (!_isLogin && i == 1);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isLogin = i == 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: on ? c.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: on
                                      ? [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: .08),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1))
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(tabs[i],
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: on ? c.text : c.stone)),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_isLogin) ...[
                      AppField(tr('email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _fieldErrors['email']),
                      AppField(tr('password'),
                          controller: _password,
                          obscure: true,
                          errorText: _fieldErrors['password']),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(tr('forgotPassword'),
                            style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenMid)),
                      ),
                    ] else ...[
                      AppField(tr('fullName'),
                          controller: _name,
                          errorText: _fieldErrors['name']),
                      AppField(tr('phone'),
                          controller: _phone,
                          hint: '05xxxxxxxx',
                          keyboardType: TextInputType.phone,
                          errorText: _fieldErrors['phone']),
                      AppField(tr('company'),
                          controller: _company,
                          errorText: _fieldErrors['company_name']),
                      AppField(tr('email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _fieldErrors['email']),
                      AppField(tr('password'),
                          controller: _password,
                          obscure: true,
                          errorText: _fieldErrors['password']),
                      AppField(tr('passwordConfirm'),
                          controller: _password2,
                          obscure: true,
                          errorText: _fieldErrors['password_confirmation']),
                      const SizedBox(height: 4),
                    ],
                    AppButton(
                      _isLogin ? tr('doLogin') : tr('doRegister'),
                      loading: _busy,
                      onTap: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (r) => false),
                  child: Text(tr('continueGuest'),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: c.stone)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
