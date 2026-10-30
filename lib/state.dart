import 'package:flutter/widgets.dart';

import 'models.dart';

/// وضعیت کل برنامه (نسخه نمایشی: همه چیز فقط در حافظه نگهداری می‌شود).
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  AppUser? me;
  bool dark = false;
  int _counter = 100;

  String _id() => 'x${_counter++}';

  final List<AppUser> users = [];
  final List<Chat> chats = [];
  final List<ChatRequest> requests = [];
  final List<GroupChat> groups = [];
  final List<Report> reports = [];
  final List<AuditEntry> audit = [];
  final List<AdCampaign> ads = [];
  final Set<String> myBlocked = {};

  void _log(String actor, String action) {
    audit.insert(
      0,
      AuditEntry(time: DateTime.now(), actor: actor, action: action),
    );
  }

  void _seed() {
    final seeded = <AppUser>[
      AppUser(
        id: 'u1',
        phone: '09121111111',
        firstName: 'نگار',
        lastName: 'رضایی',
        instagram: 'negar.r',
        gender: Gender.female,
        password: '123456',
        bio: 'عاشق قهوه و کتاب',
        dx: 0.30,
        dy: 0.35,
        distanceKm: 1.2,
      ),
      AppUser(
        id: 'u2',
        phone: '09122222001',
        firstName: 'علی',
        lastName: 'کریمی',
        instagram: 'ali.karimi',
        gender: Gender.male,
        password: '123456',
        bio: 'دوچرخه‌سوار و اهل سفر',
        dx: 0.65,
        dy: 0.30,
        distanceKm: 2.5,
      ),
      AppUser(
        id: 'u3',
        phone: '09122222002',
        firstName: 'مریم',
        lastName: 'حسینی',
        instagram: 'maryam.h',
        gender: Gender.female,
        password: '123456',
        bio: 'طراح و علاقه‌مند به عکاسی',
        online: false,
        dx: 0.20,
        dy: 0.60,
        distanceKm: 3.1,
      ),
      AppUser(
        id: 'u4',
        phone: '09122222003',
        firstName: 'رضا',
        lastName: 'محمدی',
        instagram: 'reza.m',
        gender: Gender.male,
        password: '123456',
        bio: 'برنامه‌نویس',
        dx: 0.75,
        dy: 0.62,
        distanceKm: 4.8,
      ),
      AppUser(
        id: 'u5',
        phone: '09122222004',
        firstName: 'سارا',
        lastName: 'نجفی',
        instagram: 'sara.n',
        gender: Gender.female,
        password: '123456',
        bio: 'پیاده‌روی هر صبح',
        dx: 0.45,
        dy: 0.78,
        distanceKm: 6.0,
      ),
      AppUser(
        id: 'u6',
        phone: '09122222005',
        firstName: 'امیر',
        lastName: 'صادقی',
        instagram: 'amir.s',
        gender: Gender.male,
        password: '123456',
        bio: 'موسیقی و فوتبال',
        online: false,
        dx: 0.55,
        dy: 0.15,
        distanceKm: 8.4,
      ),
      AppUser(
        id: 'a1',
        phone: '09120000000',
        firstName: 'مدیر',
        lastName: 'کل',
        instagram: 'dorehami.admin',
        gender: Gender.male,
        password: 'admin123',
        role: UserRole.superAdmin,
        invisible: true,
      ),
      AppUser(
        id: 'a2',
        phone: '09123333333',
        firstName: 'مدیر',
        lastName: 'پشتیبانی',
        instagram: 'dorehami.support',
        gender: Gender.female,
        password: 'admin123',
        role: UserRole.admin,
        invisible: true,
      ),
    ];
    users.addAll(seeded);

    requests.add(
      ChatRequest(user: users[5], note: 'سلام، می‌توانیم گفتگو کنیم؟'),
    );

    groups.addAll([
      GroupChat(
        id: 'g1',
        name: 'دورهمی محله',
        description: 'گروه عمومی ساکنان اطراف',
        inviteLink: 'https://dorehami.app/g/neighbors',
        isPublic: true,
        onMap: true,
        joined: false,
        members: 128,
        dx: 0.40,
        dy: 0.48,
      ),
      GroupChat(
        id: 'g2',
        name: 'پیاده‌روی صبحگاهی',
        description: 'هر روز ساعت ۶ صبح',
        inviteLink: 'https://dorehami.app/g/walk',
        isPublic: true,
        onMap: true,
        joined: false,
        members: 54,
        dx: 0.82,
        dy: 0.22,
      ),
      GroupChat(
        id: 'g3',
        name: 'دوستان من',
        description: 'گروه خصوصی',
        inviteLink: 'https://dorehami.app/g/friends',
        members: 4,
      ),
    ]);

    reports.add(
      Report(
        id: 'r1',
        reporterName: 'نگار رضایی',
        target: users[3],
        reason: 'ارسال پیام مزاحم (نمونه)',
        time: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );

    ads.addAll([
      AdCampaign(
        id: 'ad1',
        brand: 'کافه نمونه',
        title: 'قهوه اول به ما',
        text: 'با نشان دادن این تبلیغ، یک قهوه رایگان بگیرید (نمونه)',
        impressions: 120,
        clicks: 9,
      ),
      AdCampaign(
        id: 'ad2',
        brand: 'فروشگاه نمونه',
        title: 'تخفیف آخر هفته',
        text: 'تا ۳۰ درصد تخفیف روی همه کالاها (نمونه)',
        active: false,
        impressions: 40,
        clicks: 2,
      ),
    ]);

    _log('سیستم', 'داده‌های نمونه بارگذاری شد');
  }

  // ───────────── حساب کاربری ─────────────

  String? login(String phone, String password) {
    final p = normalizeDigits(phone);
    for (final u in users) {
      if (u.phone == p) {
        if (u.password != password) {
          return 'رمز عبور اشتباه است';
        }
        if (u.blocked) {
          return 'حساب شما توسط مدیریت مسدود شده است';
        }
        me = u;
        u.online = true;
        _log(u.fullName, 'ورود به حساب');
        notifyListeners();
        return null;
      }
    }
    return 'کاربری با این شماره پیدا نشد';
  }

  String? signUp({
    required String phone,
    required String firstName,
    required String lastName,
    required String instagram,
    required String password,
    required Gender gender,
    String bio = '',
  }) {
    final p = normalizeDigits(phone);
    for (final u in users) {
      if (u.phone == p) {
        return 'این شماره قبلاً ثبت‌نام کرده است';
      }
    }
    final user = AppUser(
      id: _id(),
      phone: p,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      instagram: instagram.trim().replaceFirst('@', ''),
      gender: gender,
      password: password,
      bio: bio.trim(),
    );
    users.add(user);
    me = user;
    _log(user.fullName, 'ثبت‌نام کاربر جدید');
    notifyListeners();
    return null;
  }

  bool phoneExists(String phone) {
    final p = normalizeDigits(phone);
    return users.any((u) => u.phone == p);
  }

  void resetPassword(String phone, String newPassword) {
    final p = normalizeDigits(phone);
    for (final u in users) {
      if (u.phone == p) {
        u.password = newPassword;
        _log(u.fullName, 'بازیابی رمز عبور');
      }
    }
    notifyListeners();
  }

  void logout() {
    final u = me;
    if (u != null) {
      _log(u.fullName, 'خروج از حساب');
    }
    me = null;
    notifyListeners();
  }

  void setDark(bool v) {
    dark = v;
    notifyListeners();
  }

  void setGps(bool v) {
    me?.gpsOn = v;
    notifyListeners();
  }

  void setInvisible(bool v) {
    me?.invisible = v;
    notifyListeners();
  }

  void updateProfile({
    String? firstName,
    String? lastName,
    String? instagram,
    String? bio,
  }) {
    final u = me;
    if (u == null) {
      return;
    }
    if (firstName != null) u.firstName = firstName.trim();
    if (lastName != null) u.lastName = lastName.trim();
    if (instagram != null) u.instagram = instagram.trim().replaceFirst('@', '');
    if (bio != null) u.bio = bio.trim();
    notifyListeners();
  }

  // ───────────── نقشه ─────────────

  /// کاربر فقط وقتی روی نقشه دیده می‌شود که GPS روشن، حالت نامرئی خاموش و حساب مسدود نباشد.
  bool visibleOnMap(AppUser u) {
    if (u.id == me?.id) {
      return false;
    }
    return u.gpsOn &&
        !u.invisible &&
        !u.blocked &&
        !myBlocked.contains(u.id);
  }

  List<AppUser> mapUsers({
    required double maxKm,
    Gender? gender,
    bool onlyOnline = false,
  }) {
    return users.where((u) {
      if (!visibleOnMap(u)) return false;
      if (u.distanceKm > maxKm) return false;
      if (gender != null && u.gender != gender) return false;
      if (onlyOnline && !u.online) return false;
      return true;
    }).toList();
  }

  // ───────────── گفتگو ─────────────

  Chat? chatWith(AppUser u) {
    for (final c in chats) {
      if (c.user.id == u.id) {
        return c;
      }
    }
    return null;
  }

  void sendRequest(AppUser u) {
    if (chatWith(u) != null) {
      return;
    }
    final chat = Chat(user: u, state: ChatState.pendingOut);
    chats.add(chat);
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      chat.state = ChatState.active;
      chat.messages.add(
        Message(
          id: _id(),
          fromMe: false,
          kind: MsgKind.text,
          text: 'سلام! درخواستت را پذیرفتم (پاسخ خودکار نمونه).',
          time: DateTime.now(),
        ),
      );
      notifyListeners();
    });
  }

  void acceptRequest(ChatRequest r) {
    requests.remove(r);
    final existing = chatWith(r.user);
    if (existing != null) {
      existing.state = ChatState.active;
    } else {
      final chat = Chat(user: r.user, state: ChatState.active);
      chat.messages.add(
        Message(
          id: _id(),
          fromMe: false,
          kind: MsgKind.text,
          text: r.note,
          time: DateTime.now(),
        ),
      );
      chats.add(chat);
    }
    notifyListeners();
  }

  void rejectRequest(ChatRequest r) {
    requests.remove(r);
    notifyListeners();
  }

  Message _newMsg(MsgKind kind, String text, String? replyTo) {
    return Message(
      id: _id(),
      fromMe: true,
      kind: kind,
      text: text,
      time: DateTime.now(),
      replyToText: replyTo,
    );
  }

  void _progress(Message m) {
    Future.delayed(const Duration(seconds: 1), () {
      m.status = MsgStatus.delivered;
      notifyListeners();
    });
    Future.delayed(const Duration(seconds: 2), () {
      m.status = MsgStatus.read;
      notifyListeners();
    });
  }

  void sendInChat(Chat chat, MsgKind kind, String text, {String? replyTo}) {
    if (chat.state != ChatState.active) {
      return;
    }
    final m = _newMsg(kind, text, replyTo);
    chat.messages.add(m);
    notifyListeners();
    _progress(m);
    if (kind == MsgKind.text) {
      Future.delayed(const Duration(seconds: 3), () {
        chat.messages.add(
          Message(
            id: _id(),
            fromMe: false,
            kind: MsgKind.text,
            text: 'ممنون از پیامت (پاسخ خودکار نمونه).',
            time: DateTime.now(),
          ),
        );
        notifyListeners();
      });
    }
  }

  void sendInGroup(GroupChat g, MsgKind kind, String text, {String? replyTo}) {
    final m = _newMsg(kind, text, replyTo);
    g.messages.add(m);
    notifyListeners();
    _progress(m);
  }

  void editMessage(Message m, String text) {
    m.text = text;
    m.edited = true;
    notifyListeners();
  }

  void deleteMessage(List<Message> list, Message m) {
    list.remove(m);
    notifyListeners();
  }

  void toggleMuteChat(Chat c) {
    c.muted = !c.muted;
    notifyListeners();
  }

  void blockUser(AppUser u) {
    myBlocked.add(u.id);
    final c = chatWith(u);
    if (c != null) {
      chats.remove(c);
    }
    requests.removeWhere((r) => r.user.id == u.id);
    _log(me?.fullName ?? '-', 'مسدود کردن ${u.fullName}');
    notifyListeners();
  }

  void unblockUser(AppUser u) {
    myBlocked.remove(u.id);
    notifyListeners();
  }

  void reportUser(AppUser u, String reason) {
    reports.insert(
      0,
      Report(
        id: _id(),
        reporterName: me?.fullName ?? '-',
        target: u,
        reason: reason,
        time: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // ───────────── گروه‌ها ─────────────

  GroupChat createGroup(String name, {required bool isPublic, required bool onMap}) {
    final g = GroupChat(
      id: _id(),
      name: name.trim(),
      description: 'گروه ساخته‌شده توسط ${me?.fullName ?? ''}',
      inviteLink: 'https://dorehami.app/g/$_counter',
      isPublic: isPublic,
      onMap: isPublic && onMap,
      dx: 0.5,
      dy: 0.5,
    );
    groups.insert(0, g);
    _log(me?.fullName ?? '-', 'ساخت گروه «${g.name}»');
    notifyListeners();
    return g;
  }

  void joinGroup(GroupChat g) {
    g.joined = true;
    g.members += 1;
    notifyListeners();
  }

  void toggleMuteGroup(GroupChat g) {
    g.muted = !g.muted;
    notifyListeners();
  }

  // ───────────── مدیریت ─────────────

  bool get isStaff => me?.isStaff ?? false;
  bool get isSuper => me?.role == UserRole.superAdmin;

  int get onlineCount => users.where((u) => u.online && !u.isStaff).length;
  int get openReports => reports.where((r) => !r.resolved).length;
  int get totalImpressions => ads.fold(0, (s, a) => s + a.impressions);
  int get totalClicks => ads.fold(0, (s, a) => s + a.clicks);

  void adminToggleBlock(AppUser u) {
    u.blocked = !u.blocked;
    _log(me?.fullName ?? '-',
        '${u.blocked ? 'مسدود کردن' : 'رفع مسدودیت'} ${u.fullName}');
    notifyListeners();
  }

  void resolveReport(Report r, {bool blockTarget = false}) {
    r.resolved = true;
    if (blockTarget && !r.target.blocked) {
      r.target.blocked = true;
    }
    _log(me?.fullName ?? '-',
        'بررسی گزارش علیه ${r.target.fullName}${blockTarget ? ' و مسدودسازی' : ''}');
    notifyListeners();
  }

  void setRole(AppUser u, UserRole role) {
    u.role = role;
    _log(me?.fullName ?? '-', 'تغییر سطح ${u.fullName} به ${role.label}');
    notifyListeners();
  }

  // ───────────── تبلیغات ─────────────

  AdCampaign? get activeAd {
    for (final a in ads) {
      if (a.active) {
        return a;
      }
    }
    return null;
  }

  void adImpression(AdCampaign a) {
    a.impressions += 1;
  }

  void adClick(AdCampaign a) {
    a.clicks += 1;
    notifyListeners();
  }

  void addAd(String brand, String title) {
    ads.insert(
      0,
      AdCampaign(
        id: _id(),
        brand: brand.trim(),
        title: title.trim(),
        text: 'کمپین نمونه',
      ),
    );
    _log(me?.fullName ?? '-', 'افزودن کمپین «$title»');
    notifyListeners();
  }

  void toggleAd(AdCampaign a) {
    a.active = !a.active;
    _log(me?.fullName ?? '-',
        '${a.active ? 'فعال‌سازی' : 'توقف'} کمپین «${a.title}»');
    notifyListeners();
  }
}

/// دسترسی به وضعیت برنامه از هر جای درخت ویجت‌ها.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
