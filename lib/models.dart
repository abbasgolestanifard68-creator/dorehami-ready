enum Gender { male, female }

extension GenderLabel on Gender {
  String get label => this == Gender.male ? 'مرد' : 'زن';
}

enum UserRole { user, admin, superAdmin }

extension RoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'کاربر';
      case UserRole.admin:
        return 'مدیر';
      case UserRole.superAdmin:
        return 'مدیر کل';
    }
  }
}

enum MsgKind { text, photo, video, audio }

enum MsgStatus { sent, delivered, read }

enum ChatState { pendingOut, active }

String hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String normalizeDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final i = fa.indexOf(c);
    final j = ar.indexOf(c);
    if (i >= 0) {
      b.write(i);
    } else if (j >= 0) {
      b.write(j);
    } else {
      b.write(c);
    }
  }
  return b.toString().trim();
}

class AppUser {
  AppUser({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.instagram,
    required this.gender,
    this.password = '',
    this.bio = '',
    this.online = true,
    this.invisible = false,
    this.gpsOn = true,
    this.blocked = false,
    this.role = UserRole.user,
    this.dx = 0.5,
    this.dy = 0.5,
    this.distanceKm = 0,
  });

  final String id;
  String phone;
  String firstName;
  String lastName;
  String instagram;
  Gender gender;
  String password;
  String bio;
  bool online;
  bool invisible;
  bool gpsOn;
  bool blocked;
  UserRole role;
  double dx;
  double dy;
  double distanceKm;

  String get fullName => '$firstName $lastName';
  bool get isStaff => role != UserRole.user;
}

class Message {
  Message({
    required this.id,
    required this.fromMe,
    required this.kind,
    required this.time,
    this.text = '',
    this.status = MsgStatus.sent,
    this.replyToText,
    this.edited = false,
  });

  final String id;
  final bool fromMe;
  final MsgKind kind;
  final DateTime time;
  String text;
  MsgStatus status;
  String? replyToText;
  bool edited;

  String get preview {
    switch (kind) {
      case MsgKind.text:
        return text;
      case MsgKind.photo:
        return 'تصویر';
      case MsgKind.video:
        return 'ویدیو';
      case MsgKind.audio:
        return 'پیام صوتی';
    }
  }
}

class Chat {
  Chat({required this.user, required this.state});

  final AppUser user;
  ChatState state;
  bool muted = false;
  final List<Message> messages = [];
}

class ChatRequest {
  ChatRequest({required this.user, required this.note});

  final AppUser user;
  final String note;
}

class GroupChat {
  GroupChat({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteLink,
    this.isPublic = false,
    this.onMap = false,
    this.joined = true,
    this.members = 1,
    this.dx = 0.5,
    this.dy = 0.5,
  });

  final String id;
  String name;
  String description;
  final String inviteLink;
  bool isPublic;
  bool onMap;
  bool joined;
  int members;
  double dx;
  double dy;
  bool muted = false;
  final List<Message> messages = [];
}

class Report {
  Report({
    required this.id,
    required this.reporterName,
    required this.target,
    required this.reason,
    required this.time,
  });

  final String id;
  final String reporterName;
  final AppUser target;
  final String reason;
  final DateTime time;
  bool resolved = false;
}

class AuditEntry {
  AuditEntry({required this.time, required this.actor, required this.action});

  final DateTime time;
  final String actor;
  final String action;
}

class AdCampaign {
  AdCampaign({
    required this.id,
    required this.brand,
    required this.title,
    required this.text,
    this.active = true,
    this.impressions = 0,
    this.clicks = 0,
  });

  final String id;
  String brand;
  String title;
  String text;
  bool active;
  int impressions;
  int clicks;
}
