import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'state.dart';
import 'updater.dart';
import 'widgets.dart';

// ───────────────────────── نقشه ─────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Gender? _gender;
  bool _onlyOnline = false;
  double _maxKm = 10;

  void _openUser(AppUser u) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _UserSheet(user: u),
    );
  }

  void _openGroup(GroupChat g) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final state = AppScope.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.name, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${g.description} • ${g.members} عضو'),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.login),
                label: Text(g.joined ? 'باز کردن گروه' : 'عضویت در گروه'),
                onPressed: () {
                  if (!g.joined) {
                    state.joinGroup(g);
                  }
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(group: g),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final me = state.me!;
    final hidden = !me.gpsOn || me.invisible;
    final users = state.mapUsers(
      maxKm: _maxKm,
      gender: _gender,
      onlyOnline: _onlyOnline,
    );
    final groupsOnMap = state.groups.where((g) => g.isPublic && g.onMap).toList();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          const AdBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('همه'),
                  selected: _gender == null,
                  onSelected: (_) => setState(() => _gender = null),
                ),
                ChoiceChip(
                  label: const Text('مرد'),
                  selected: _gender == Gender.male,
                  onSelected: (_) => setState(() => _gender = Gender.male),
                ),
                ChoiceChip(
                  label: const Text('زن'),
                  selected: _gender == Gender.female,
                  onSelected: (_) => setState(() => _gender = Gender.female),
                ),
                FilterChip(
                  label: const Text('فقط آنلاین'),
                  selected: _onlyOnline,
                  onSelected: (v) => setState(() => _onlyOnline = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('تا ${_maxKm.round()} کیلومتر'),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 20,
                    divisions: 19,
                    value: _maxKm,
                    onChanged: (v) => setState(() => _maxKm = v),
                  ),
                ),
              ],
            ),
          ),
          if (hidden)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                !me.gpsOn
                    ? 'GPS شما خاموش است؛ موقعیت شما برای دیگران در دسترس نیست.'
                    : 'حالت نامرئی فعال است؛ دیگران شما را روی نقشه نمی‌بینند.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapPainter(
                            background: scheme.surfaceContainerHighest,
                            line: scheme.outlineVariant,
                            ring: scheme.primary,
                          ),
                        ),
                      ),
                      for (final g in groupsOnMap)
                        Positioned(
                          left: g.dx * w - 20,
                          top: g.dy * h - 20,
                          child: GestureDetector(
                            onTap: () => _openGroup(g),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: scheme.tertiary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.groups, color: scheme.onTertiary),
                            ),
                          ),
                        ),
                      for (final u in users)
                        Positioned(
                          left: u.dx * w - 22,
                          top: u.dy * h - 22,
                          child: GestureDetector(
                            onTap: () => _openUser(u),
                            child: UserAvatar(user: u),
                          ),
                        ),
                      Positioned(
                        left: w * 0.5 - 18,
                        top: h * 0.5 - 18,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Icon(Icons.person, size: 18, color: scheme.onPrimary),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${users.length} نفر در اطراف • نقشه نمایشی',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.background, required this.line, required this.ring});

  final Color background;
  final Color line;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final p = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      final y = size.height * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final center = Offset(size.width / 2, size.height / 2);
    final r = Paint()
      ..color = ring.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, size.shortestSide * 0.16 * i, r);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.background != background || old.line != line || old.ring != ring;
}

class _UserSheet extends StatelessWidget {
  const _UserSheet({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final chat = state.chatWith(user);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(user: user, radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
                    Text('${user.gender.label} • ${user.distanceKm} کیلومتر • '
                        '${user.online ? 'آنلاین' : 'آفلاین'}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user.bio.isNotEmpty) Text(user.bio),
          const SizedBox(height: 4),
          Text(
            'اینستاگرام: @${user.instagram}',
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.chat),
                  label: Text(chat == null
                      ? 'درخواست چت'
                      : chat.state == ChatState.pendingOut
                          ? 'درخواست ارسال شده'
                          : 'باز کردن چت'),
                  onPressed: chat != null && chat.state == ChatState.pendingOut
                      ? null
                      : () {
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          if (chat == null) {
                            state.sendRequest(user);
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('درخواست چت برای ${user.firstName} ارسال شد'),
                              ),
                            );
                          } else {
                            nav.pop();
                            nav.push(MaterialPageRoute<void>(
                              builder: (_) => ChatScreen(chat: chat),
                            ));
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'گزارش',
                icon: const Icon(Icons.flag_outlined),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final reason = await askText(
                    context,
                    title: 'دلیل گزارش',
                    hint: 'مثلاً پیام مزاحم',
                  );
                  if (reason != null && reason.trim().isNotEmpty) {
                    state.reportUser(user, reason.trim());
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('گزارش ثبت شد')),
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                tooltip: 'مسدود کردن',
                icon: const Icon(Icons.block),
                onPressed: () {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  state.blockUser(user);
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('${user.firstName} مسدود شد')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── گفتگوها ─────────────────────────

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('گفتگوها', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          if (state.requests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('درخواست‌های چت'),
            ),
            for (final r in state.requests)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: UserAvatar(user: r.user),
                  title: Text(r.user.fullName),
                  subtitle: Text(r.note),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'رد',
                        icon: const Icon(Icons.close),
                        onPressed: () => state.rejectRequest(r),
                      ),
                      IconButton(
                        tooltip: 'پذیرش',
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () => state.acceptRequest(r),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(),
          ],
          if (state.chats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'هنوز گفتگویی ندارید. از روی نقشه برای یک نفر درخواست چت بفرستید.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final c in state.chats)
            ListTile(
              leading: UserAvatar(user: c.user),
              title: Text(c.user.fullName),
              subtitle: Text(
                c.state == ChatState.pendingOut
                    ? 'در انتظار پذیرش درخواست'
                    : c.messages.isEmpty
                        ? 'گفتگو را شروع کنید'
                        : c.messages.last.preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: c.muted ? const Icon(Icons.volume_off, size: 18) : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ChatScreen(chat: c)),
              ),
              onLongPress: () => state.toggleMuteChat(c),
            ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.chat, this.group})
      : assert(chat != null || group != null);

  final Chat? chat;
  final GroupChat? group;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Message? _replyTo;
  Message? _editing;

  List<Message> get _messages =>
      widget.chat != null ? widget.chat!.messages : widget.group!.messages;

  bool get _canSend =>
      widget.group != null || widget.chat!.state == ChatState.active;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send(MsgKind kind, String text) {
    final state = AppScope.of(context);
    if (_editing != null && kind == MsgKind.text) {
      state.editMessage(_editing!, text);
      setState(() => _editing = null);
      _text.clear();
      return;
    }
    final reply = _replyTo?.preview;
    if (widget.chat != null) {
      state.sendInChat(widget.chat!, kind, text, replyTo: reply);
    } else {
      state.sendInGroup(widget.group!, kind, text, replyTo: reply);
    }
    setState(() => _replyTo = null);
    _text.clear();
    _toBottom();
  }

  void _attach() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('ارسال تصویر (نمونه)'),
              onTap: () {
                Navigator.pop(ctx);
                _send(MsgKind.photo, 'تصویر نمونه');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('ارسال ویدیو (نمونه)'),
              onTap: () {
                Navigator.pop(ctx);
                _send(MsgKind.video, 'ویدیوی نمونه');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('ارسال پیام صوتی (نمونه)'),
              onTap: () {
                Navigator.pop(ctx);
                _send(MsgKind.audio, 'پیام صوتی نمونه');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _actions(Message m) {
    final state = AppScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('پاسخ'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _replyTo = m;
                  _editing = null;
                });
              },
            ),
            if (m.fromMe && m.kind == MsgKind.text)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('ویرایش'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _editing = m;
                    _replyTo = null;
                    _text.text = m.text;
                  });
                },
              ),
            if (m.fromMe)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('حذف'),
                onTap: () {
                  Navigator.pop(ctx);
                  state.deleteMessage(_messages, m);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final chat = widget.chat;
    final group = widget.group;
    final title = chat != null ? chat.user.fullName : group!.name;
    final scheme = Theme.of(context).colorScheme;
    final messages = _messages;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (group != null)
            IconButton(
              tooltip: 'کپی لینک دعوت',
              icon: const Icon(Icons.link),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.inviteLink));
                toast(context, 'لینک دعوت کپی شد');
              },
            ),
          IconButton(
            tooltip: 'بی‌صدا',
            icon: Icon(
              (chat?.muted ?? group!.muted) ? Icons.volume_off : Icons.volume_up,
            ),
            onPressed: () {
              if (chat != null) {
                state.toggleMuteChat(chat);
              } else {
                state.toggleMuteGroup(group!);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_canSend)
            Container(
              width: double.infinity,
              color: scheme.tertiaryContainer,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'درخواست چت ارسال شد. تا پذیرش طرف مقابل نمی‌توانید پیام بدهید.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('هنوز پیامی نیست'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _Bubble(
                      message: messages[i],
                      onLongPress: () => _actions(messages[i]),
                    ),
                  ),
          ),
          if (_replyTo != null || _editing != null)
            Container(
              color: scheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(_editing != null ? Icons.edit : Icons.reply, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editing != null
                          ? 'ویرایش پیام'
                          : 'پاسخ به: ${_replyTo!.preview}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _replyTo = null;
                      _editing = null;
                      _text.clear();
                    }),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _canSend ? _attach : null,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      enabled: _canSend,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'پیام...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _canSend
                        ? () {
                            final t = _text.text.trim();
                            if (t.isNotEmpty) {
                              _send(MsgKind.text, t);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onLongPress});

  final Message message;
  final VoidCallback onLongPress;

  IconData get _kindIcon {
    switch (message.kind) {
      case MsgKind.photo:
        return Icons.photo;
      case MsgKind.video:
        return Icons.videocam;
      case MsgKind.audio:
        return Icons.mic;
      case MsgKind.text:
        return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.fromMe;
    // در راست‌به‌چین، شروع = سمت راست؛ پیام‌های من سمت شروع می‌آیند.
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.replyToText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.surface.withAlpha(140),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.replyToText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (message.kind == MsgKind.text)
                Text(message.text)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_kindIcon, size: 20),
                    const SizedBox(width: 6),
                    Text(message.text),
                  ],
                ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${message.edited ? 'ویرایش‌شده • ' : ''}${hm(message.time)}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.status == MsgStatus.sent ? Icons.check : Icons.done_all,
                      size: 14,
                      color: message.status == MsgStatus.read ? Colors.blue : null,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── گروه‌ها ─────────────────────────

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final state = AppScope.of(context);
    final nameCtl = TextEditingController();
    var isPublic = false;
    var onMap = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('ساخت گروه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'نام گروه'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('گروه عمومی'),
                value: isPublic,
                onChanged: (v) => setS(() {
                  isPublic = v;
                  if (!v) onMap = false;
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('نمایش روی نقشه'),
                value: onMap,
                onChanged: isPublic ? (v) => setS(() => onMap = v) : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ساخت'),
            ),
          ],
        ),
      ),
    );
    final name = nameCtl.text;
    nameCtl.dispose();
    if (ok == true && name.trim().isNotEmpty) {
      final g = state.createGroup(name, isPublic: isPublic, onMap: onMap);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ChatScreen(group: g)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = state.groups.where((g) => g.joined).toList();
    final discover = state.groups.where((g) => !g.joined && g.isPublic).toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('گروه جدید'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('گروه‌ها', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            for (final g in mine)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(g.name),
                subtitle: Text(
                  '${g.members} عضو • ${g.isPublic ? 'عمومی' : 'خصوصی'}'
                  '${g.onMap ? ' • روی نقشه' : ''}',
                ),
                trailing: g.muted ? const Icon(Icons.volume_off, size: 18) : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ChatScreen(group: g)),
                ),
              ),
            if (discover.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('گروه‌های عمومی اطراف'),
              ),
              for (final g in discover)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.public)),
                  title: Text(g.name),
                  subtitle: Text('${g.description} • ${g.members} عضو'),
                  trailing: OutlinedButton(
                    onPressed: () => state.joinGroup(g),
                    child: const Text('عضویت'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── پروفایل ─────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    String title,
    String current,
    void Function(String) save, {
    int maxLines = 1,
  }) async {
    final v = await askText(context, title: title, initial: current, maxLines: maxLines);
    if (v != null && (v.trim().isNotEmpty || maxLines > 1)) {
      save(v);
    }
  }

  Future<void> _checkUpdate(BuildContext context) async {
    if (!Updater.configured) {
      toast(context, 'نشانی سرور به‌روزرسانی هنوز تنظیم نشده است');
      return;
    }
    toast(context, 'در حال بررسی...');
    final info = await Updater.check(force: true);
    if (!context.mounted) {
      return;
    }
    if (info == null) {
      toast(context, 'شما از آخرین نسخه استفاده می‌کنید');
    } else {
      await showUpdateDialog(context, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final me = state.me!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: UserAvatar(user: me, radius: 40)),
          const SizedBox(height: 8),
          Center(
            child: Text(me.fullName, style: Theme.of(context).textTheme.titleLarge),
          ),
          Center(child: Text('${me.gender.label} • ${me.role.label}')),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('نام و نام خانوادگی'),
                  subtitle: Text(me.fullName),
                  onTap: () async {
                    final f = await askText(context, title: 'نام', initial: me.firstName);
                    if (f == null || !context.mounted) return;
                    final l = await askText(
                      context,
                      title: 'نام خانوادگی',
                      initial: me.lastName,
                    );
                    if (l == null) return;
                    if (f.trim().isNotEmpty && l.trim().isNotEmpty) {
                      state.updateProfile(firstName: f, lastName: l);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('آیدی اینستاگرام'),
                  subtitle: Text('@${me.instagram}'),
                  onTap: () => _edit(
                    context,
                    'آیدی اینستاگرام',
                    me.instagram,
                    (v) => state.updateProfile(instagram: v),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notes),
                  title: const Text('بیوگرافی'),
                  subtitle: Text(me.bio.isEmpty ? 'افزودن بیوگرافی' : me.bio),
                  onTap: () => _edit(
                    context,
                    'بیوگرافی',
                    me.bio,
                    (v) => state.updateProfile(bio: v),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.gps_fixed),
                  title: const Text('GPS'),
                  subtitle: const Text('با خاموش کردن، موقعیت شما برای دیگران در دسترس نیست'),
                  value: me.gpsOn,
                  onChanged: state.setGps,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('حالت نامرئی'),
                  subtitle: const Text('روی نقشه دیده نمی‌شوید'),
                  value: me.invisible,
                  onChanged: state.setInvisible,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('پوسته تیره'),
                  value: state.dark,
                  onChanged: state.setDark,
                ),
              ],
            ),
          ),
          if (state.myBlocked.isNotEmpty)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.block),
                title: Text('کاربران مسدود (${state.myBlocked.length})'),
                children: [
                  for (final u in state.users.where((u) => state.myBlocked.contains(u.id)))
                    ListTile(
                      title: Text(u.fullName),
                      trailing: TextButton(
                        onPressed: () => state.unblockUser(u),
                        child: const Text('رفع مسدودیت'),
                      ),
                    ),
                ],
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('به‌روزرسانی اپلیکیشن'),
              subtitle: Text(
                'نسخه ${Updater.currentVersion} (ساخت ${Updater.currentBuildNumber})',
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _checkUpdate(context),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('خروج از حساب'),
            onPressed: state.logout,
          ),
        ],
      ),
    );
  }
}
