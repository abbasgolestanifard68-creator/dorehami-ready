import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class UpdateInfo {
  UpdateInfo({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.sha256,
    required this.notes,
  });

  final String version;
  final int build;
  final String apkUrl;
  final String sha256;
  final String notes;
}

/// بررسی و نصب نسخه جدید.
/// نشانی manifest هنگام ساخت با DOREHAMI_UPDATE_MANIFEST_URL تنظیم می‌شود.
class Updater {
  static const String manifestUrl =
      String.fromEnvironment('DOREHAMI_UPDATE_MANIFEST_URL');

  // هنگام انتشار، این مقدار و version در pubspec.yaml باید هم‌زمان زیاد شوند.
  static const int currentBuildNumber = 7;
  static const String currentVersion = '0.7.0';

  static const MethodChannel _channel = MethodChannel('dorehami/updater');
  static const Duration minInterval = Duration(minutes: 3);
  static DateTime? _lastCheck;

  static bool get configured => manifestUrl.startsWith('https://');

  /// اگر نسخه جدیدتر باشد اطلاعات آن را برمی‌گرداند، وگرنه null.
  static Future<UpdateInfo?> check({bool force = false}) async {
    if (!configured) {
      return null;
    }
    final now = DateTime.now();
    final last = _lastCheck;
    if (!force && last != null && now.difference(last) < minInterval) {
      return null;
    }
    _lastCheck = now;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final req = await client
            .getUrl(Uri.parse(manifestUrl))
            .timeout(const Duration(seconds: 10));
        final res = await req.close().timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          return null;
        }
        final body = await res
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 15));
        final json = jsonDecode(body);
        if (json is! Map<String, dynamic>) {
          return null;
        }
        final build = json['latestBuild'];
        final apk = json['apkUrl'];
        final sha = json['sha256'];
        if (build is! int || apk is! String || sha is! String) {
          return null;
        }
        if (build <= currentBuildNumber) {
          return null;
        }
        if (!apk.startsWith('https://') || sha.length != 64) {
          return null;
        }
        return UpdateInfo(
          version: (json['latestVersion'] ?? '').toString(),
          build: build,
          apkUrl: apk,
          sha256: sha.toLowerCase(),
          notes: (json['releaseNotes'] ?? '').toString(),
        );
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }

  /// دانلود، بررسی SHA-256 در کد بومی و باز کردن نصب‌کننده اندروید.
  /// خروجی: started / need_permission یا پیام خطا.
  static Future<String> downloadAndInstall(UpdateInfo info) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'downloadAndInstall',
        {'url': info.apkUrl, 'sha256': info.sha256},
      );
      return result ?? 'error';
    } on PlatformException catch (e) {
      return e.message ?? e.code;
    } on MissingPluginException {
      return 'این قابلیت فقط روی اندروید در دسترس است';
    }
  }
}
