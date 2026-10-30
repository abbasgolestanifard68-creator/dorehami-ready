import 'package:flutter/material.dart';

import 'models.dart';
import 'state.dart';
import 'updater.dart';

/// جایگاه نمایشی تبلیغ برند.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  String? _countedId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ad = state.activeAd;
    if (ad == null) {
      return const SizedBox.shrink();
    }
    if (_countedId != ad.id) {
      _countedId = ad.id;
      state.adImpression(ad);
    }
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: scheme.secondaryContainer,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.campaign_outlined),
        title: Text('${ad.brand} — ${ad.title}'),
        subtitle: Text(ad.text),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('تبلیغ', style: TextStyle(fontSize: 11)),
            ),
            const Icon(Icons.chevron_left),
          ],
        ),
        onTap: () {
          state.adClick(ad);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('نمونه: اینجا لینک مقصد تبلیغ باز می‌شود')),
          );
        },
      ),
    );
  }
}

/// آواتار کاربر با نقطه وضعیت آنلاین.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 22});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color =
        user.gender == Gender.female ? Colors.pink.shade300 : Colors.blue.shade400;
    final initial = user.firstName.isEmpty ? '?' : user.firstName.substring(0, 1);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color,
          child: Text(
            initial,
            style: TextStyle(color: Colors.white, fontSize: radius * 0.9),
          ),
        ),
        if (user.online)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  int maxLines = 1,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('تأیید'),
        ),
      ],
    ),
  );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('نسخه جدید موجود است'),
        content: Text(
          'نسخه ${info.version} (ساخت ${info.build})'
          '${info.notes.isEmpty ? '' : '\n\n${info.notes}'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بعداً'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final r = await Updater.downloadAndInstall(info);
              String msg;
              if (r == 'started') {
                msg = 'نصب‌کننده اندروید باز شد؛ نصب را تأیید کنید.';
              } else if (r == 'need_permission') {
                msg = 'اجازه نصب از این منبع را در تنظیمات فعال و دوباره تلاش کنید.';
              } else {
                msg = 'به‌روزرسانی انجام نشد: $r';
              }
              messenger.showSnackBar(SnackBar(content: Text(msg)));
            },
            child: const Text('دریافت و نصب'),
          ),
        ],
      );
    },
  );
}
