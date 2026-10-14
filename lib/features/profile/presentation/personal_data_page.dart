import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/failure.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_backdrop.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../l10n/strings.dart';
import '../cubit/personal_data_cubit.dart';

class PersonalDataPage extends StatefulWidget {
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _seeded = false;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    context.read<PersonalDataCubit>().load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _seed(PersonalDataState state) {
    final profile = state.profile;
    if (_seeded || profile == null) return;
    _seeded = true;
    _name.text = profile.name;
    _email.text = profile.email;
    _phone.text = profile.phone;
    _company.text = profile.companyName;
  }

  Future<void> _save() async {
    final failure = await context.read<PersonalDataCubit>().save(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          company: _company.text.trim(),
        );
    if (!mounted) return;
    _showResult(failure);
  }

  Future<void> _changePassword() async {
    if (_password.text != _confirm.text) {
      setState(() => _errors = {'password_confirmation': tr('passwordMismatch')});
      return;
    }
    final failure = await context.read<PersonalDataCubit>().changePassword(
          currentPassword: _current.text,
          password: _password.text,
          passwordConfirmation: _confirm.text,
        );
    if (!mounted) return;
    if (failure == null) {
      _current.clear();
      _password.clear();
      _confirm.clear();
    }
    _showResult(failure);
  }

  void _showResult(Failure? failure) {
    if (failure == null) {
      setState(() => _errors = const {});
      showToast(context, tr('savedOK'));
      return;
    }
    setState(() => _errors = failure.firstFieldErrors);
    if (failure.fieldErrors.isEmpty) {
      showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PersonalDataCubit, PersonalDataState>(
      listener: (context, state) => _seed(state),
      builder: (context, state) {
        return AppScaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                BackHeader(tr('personalData')),
                if (state.loading && state.profile == null)
                  const SkeletonRows(count: 3)
                else if (state.profile == null)
                  EmptyState(
                    Icons.person_outline,
                    state.error ?? tr('loadFailed'),
                    cta: tr('retry'),
                    onCta: () => context.read<PersonalDataCubit>().load(),
                  )
                else ...[
                  AppField(
                    tr('fullName'),
                    controller: _name,
                    errorText: _errors['name'],
                  ),
                  AppField(
                    tr('email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _errors['email'],
                  ),
                  AppField(
                    tr('phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    errorText: _errors['phone'],
                  ),
                  AppField(
                    tr('company'),
                    controller: _company,
                    errorText: _errors['company_name'],
                  ),
                  AppButton(
                    tr('save'),
                    loading: state.savingProfile,
                    onTap: state.savingProfile ? null : _save,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('changePassword'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.col.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppField(
                    tr('currentPassword'),
                    controller: _current,
                    obscure: true,
                    errorText: _errors['current_password'],
                  ),
                  AppField(
                    tr('newPassword'),
                    controller: _password,
                    obscure: true,
                    errorText: _errors['password'],
                  ),
                  AppField(
                    tr('passwordConfirm'),
                    controller: _confirm,
                    obscure: true,
                    errorText: _errors['password_confirmation'],
                  ),
                  AppButton(
                    tr('changePassword'),
                    variant: AppButtonVariant.outline,
                    loading: state.savingPassword,
                    onTap: state.savingPassword ? null : _changePassword,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
