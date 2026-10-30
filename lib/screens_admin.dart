import 'package:flutter/material.dart';

import 'models.dart';
import 'state.dart';
import 'widgets.dart';

/// پنل مدیریت: مدیر عادی کاربران و گزارش‌ها را می‌بیند؛ مدیر کل به همه بخش‌ها دسترسی دارد.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isSuper = state.isSuper;
    final tabs = <Tab>[
      const Tab(text: 'داشبورد'),
      const Tab(text: 'کاربران'),
      const Tab(text: 'گزارش‌ها'),
      if (isSuper) const Tab(text: 'تبلیغات برندها'),
      if (isSuper) const Tab(text: 'مدیران'),
      const Tab(text: 'گزارش عملیات'),
    ];
    final pages = <Widget>[
      const _Dashboard(),
      const _UsersTab(),
      const _ReportsTab(),
      if (isSuper) const _AdsTab(),
      if (isSuper) const _AdminsTab(),
      const _AuditTab(),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('پنل مدیریت (${state.me!.role.label})'),
          bottom: TabBar(isScrollable: true, tabs: tabs),
        ),
        body: TabBarView(children: pages),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final stats = <(String, String, IconData)>[
      ('کاربران', '${s.users.where((u) => !u.isStaff).length}', Icons.people),
      ('آنلاین', '${s.onlineCount}', Icons.circle),
      ('گروه‌ها', '${s.groups.length}', Icons.groups),
      ('گزارش باز', '${s.openReports}', Icons.flag),
      ('نمایش تبلیغ (نمونه)', '${s.totalImpressions}', Icons.visibility),
      ('کلیک تبلیغ (نمونه)', '${s.totalClicks}', Icons.touch_app),
    ];
    return GridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        for (final st in stats)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(st.$3),
                  const SizedBox(height: 4),
                  Text(st.$2, style: Theme.of(context).textTheme.headlineSmall),
                  Text(st.$1, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      children: [
        for (final u in s.users)
          ListTile(
            leading: UserAvatar(user: u),
            title: Text(u.fullName),
            subtitle: Text(
              '${u.phone} • ${u.gender.label} • ${u.role.label}'
              '${u.blocked ? ' • مسدود' : ''}',
            ),
            trailing: u.id == s.me!.id || u.role == UserRole.superAdmin
                ? null
                : TextButton(
                    onPressed: () => s.adminToggleBlock(u),
                    child: Text(u.blocked ? 'رفع مسدودیت' : 'مسدود'),
                  ),
          ),
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.reports.isEmpty) {
      return const Center(child: Text('گزارشی وجود ندارد'));
    }
    return ListView(
      children: [
        for (final r in s.reports)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('علیه: ${r.target.fullName}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('گزارش‌دهنده: ${r.reporterName} • ${hm(r.time)}'),
                  const SizedBox(height: 4),
                  Text(r.reason),
                  const SizedBox(height: 8),
                  if (r.resolved)
                    const Text('بررسی شد', style: TextStyle(color: Colors.green))
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => s.resolveReport(r),
                          child: const Text('رد گزارش / بسته شد'),
                        ),
                        FilledButton(
                          onPressed: () => s.resolveReport(r, blockTarget: true),
                          child: const Text('مسدودسازی کاربر'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AdsTab extends StatelessWidget {
  const _AdsTab();

  Future<void> _add(BuildContext context) async {
    final s = AppScope.of(context);
    final brand = await askText(context, title: 'نام برند');
    if (brand == null || brand.trim().isEmpty || !context.mounted) {
      return;
    }
    final title = await askText(context, title: 'عنوان تبلیغ');
    if (title == null || title.trim().isEmpty) {
      return;
    }
    s.addAd(brand, title);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('کمپین نمونه'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'این بخش جدا از لینک‌های اختصاصی جذب کاربر است. '
              'آمار فعلی نمونه است و به سرور وصل نیست.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          for (final a in s.ads)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SwitchListTile(
                title: Text('${a.brand} — ${a.title}'),
                subtitle: Text('نمایش: ${a.impressions} • کلیک: ${a.clicks}'),
                value: a.active,
                onChanged: (_) => s.toggleAd(a),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminsTab extends StatelessWidget {
  const _AdminsTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('با روشن کردن کلید، کاربر به «مدیر» ارتقا می‌یابد.', style: TextStyle(fontSize: 12)),
        ),
        for (final u in s.users)
          ListTile(
            leading: UserAvatar(user: u),
            title: Text(u.fullName),
            subtitle: Text(u.role.label),
            trailing: u.id == s.me!.id
                ? null
                : Switch(
                    value: u.role != UserRole.user,
                    onChanged: (v) =>
                        s.setRole(u, v ? UserRole.admin : UserRole.user),
                  ),
          ),
      ],
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      children: [
        for (final e in s.audit)
          ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 20),
            title: Text(e.action),
            subtitle: Text('${e.actor} • ${hm(e.time)}'),
          ),
      ],
    );
  }
}
