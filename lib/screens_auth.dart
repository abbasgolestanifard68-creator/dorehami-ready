import 'package:flutter/material.dart';

import 'models.dart';
import 'state.dart';
import 'widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _signup = false;
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _insta = TextEditingController();
  final _pass = TextEditingController();
  final _bio = TextEditingController();
  Gender? _gender;
  bool _genderError = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _first.dispose();
    _last.dispose();
    _insta.dispose();
    _pass.dispose();
    _bio.dispose();
    super.dispose();
  }

  String? _req(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  void _submit() {
    final state = AppScope.of(context);
    setState(() {
      _error = null;
      _genderError = _signup && _gender == null;
    });
    final ok = _form.currentState?.validate() ?? false;
    if (!ok || _genderError) {
      return;
    }
    String? err;
    if (_signup) {
      err = state.signUp(
        phone: _phone.text,
        firstName: _first.text,
        lastName: _last.text,
        instagram: _insta.text,
        password: _pass.text,
        gender: _gender!,
        bio: _bio.text,
      );
    } else {
      err = state.login(_phone.text, _pass.text);
    }
    if (err != null) {
      setState(() => _error = err);
    }
  }

  Future<void> _forgot() async {
    final state = AppScope.of(context);
    final phone = await askText(
      context,
      title: 'بازیابی رمز عبور',
      hint: 'شماره موبایل ثبت‌شده',
    );
    if (phone == null || !mounted) {
      return;
    }
    if (!state.phoneExists(phone)) {
      toast(context, 'این شماره ثبت‌نام نکرده است');
      return;
    }
    toast(context, 'کد تأیید نمونه: 12345 (در نسخه واقعی با پیامک ارسال می‌شود)');
    final code = await askText(context, title: 'کد پیامک‌شده را وارد کنید');
    if (code == null || !mounted) {
      return;
    }
    if (normalizeDigits(code) != '12345') {
      toast(context, 'کد اشتباه است');
      return;
    }
    final newPass = await askText(context, title: 'رمز عبور جدید (حداقل ۶ کاراکتر)');
    if (newPass == null || !mounted) {
      return;
    }
    if (newPass.length < 6) {
      toast(context, 'رمز عبور کوتاه است');
      return;
    }
    state.resetPassword(phone, newPass);
    toast(context, 'رمز عبور تغییر کرد؛ وارد شوید');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.location_on, size: 64, color: scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'دورهمی',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _signup ? 'ساخت حساب جدید' : 'ورود به حساب',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'شماره موبایل',
                        hintText: '09123456789',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final p = normalizeDigits(v ?? '');
                        if (p.length != 11 || !p.startsWith('09')) {
                          return 'شماره موبایل معتبر نیست';
                        }
                        return null;
                      },
                    ),
                    if (_signup) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _first,
                              decoration: const InputDecoration(
                                labelText: 'نام',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => _req(v, 'نام را وارد کنید'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _last,
                              decoration: const InputDecoration(
                                labelText: 'نام خانوادگی',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => _req(v, 'نام خانوادگی را وارد کنید'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _insta,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'آیدی اینستاگرام',
                          prefixText: '@',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _req(v, 'آیدی اینستاگرام را وارد کنید'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: _hide,
                      decoration: InputDecoration(
                        labelText: 'رمز عبور',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').length < 6) {
                          return 'رمز عبور حداقل ۶ کاراکتر باشد';
                        }
                        return null;
                      },
                    ),
                    if (_signup) ...[
                      const SizedBox(height: 12),
                      const Text('جنسیت (اجباری و بعداً قابل مخفی‌کردن نیست)'),
                      const SizedBox(height: 6),
                      SegmentedButton<Gender>(
                        emptySelectionAllowed: true,
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: Gender.male, label: Text('مرد')),
                          ButtonSegment(value: Gender.female, label: Text('زن')),
                        ],
                        selected: _gender == null ? <Gender>{} : {_gender!},
                        onSelectionChanged: (s) => setState(() {
                          _gender = s.isEmpty ? null : s.first;
                          _genderError = false;
                        }),
                      ),
                      if (_genderError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'لطفاً جنسیت را انتخاب کنید',
                            style: TextStyle(color: scheme.error, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bio,
                        maxLength: 150,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'بیوگرافی (اختیاری)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: scheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(_signup ? 'ثبت‌نام' : 'ورود'),
                    ),
                    if (!_signup)
                      TextButton(
                        onPressed: _forgot,
                        child: const Text('رمز عبور را فراموش کرده‌ام'),
                      ),
                    TextButton(
                      onPressed: () => setState(() {
                        _signup = !_signup;
                        _error = null;
                      }),
                      child: Text(
                        _signup
                            ? 'حساب دارید؟ وارد شوید'
                            : 'حساب ندارید؟ ثبت‌نام کنید',
                      ),
                    ),
                    if (!_signup) ...[
                      const Divider(),
                      const Text(
                        'ورود نمونه:\n'
                        'کاربر: 09121111111 / 123456\n'
                        'مدیر کل: 09120000000 / admin123\n'
                        'مدیر: 09123333333 / admin123',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
