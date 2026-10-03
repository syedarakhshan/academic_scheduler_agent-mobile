import 'package:flutter/material.dart';
import '../../core/api/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_notification.dart';

/// Mirrors NotificationBell.js's dropdown — shown as a bottom sheet
/// on mobile instead of a floating dropdown, which is the natural
/// mobile equivalent of a header-anchored popover.
class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();

  /// Opens the sheet and returns true if anything was marked read,
  /// so the caller can refresh its own badge count.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  bool _changed = false;

  int get _unread => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await NotificationService.instance.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    setState(() {
      _notifications = [for (final x in _notifications) if (x.id == n.id) x.copyWith(isRead: true) else x];
      _changed = true;
    });
    try {
      await NotificationService.instance.markRead(n.id);
    } catch (_) {}
  }

  Future<void> _markAll() async {
    setState(() {
      _notifications = [for (final x in _notifications) x.copyWith(isRead: true)];
      _changed = true;
    });
    try {
      await NotificationService.instance.markAllRead();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              color: AppColors.navy,
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (_unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                      child: Text('$_unread new', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                  const Spacer(),
                  if (_unread > 0)
                    TextButton.icon(
                      onPressed: _markAll,
                      icon: const Icon(Icons.done_all, size: 13, color: Colors.white),
                      label: const Text('Mark all read', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(_changed),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────
            Flexible(
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.navy)))
                  : _notifications.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none, size: 34, color: Color(0xFFC8D8E0)),
                      SizedBox(height: 10),
                      Text('No notifications yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5A7080))),
                      SizedBox(height: 3),
                      Text('You are all caught up!', style: TextStyle(fontSize: 11, color: Color(0xFFAABBC8))),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _notifications.length,
                itemBuilder: (context, i) => _NotificationRow(n: _notifications[i], onMarkRead: () => _markRead(_notifications[i])),
              ),
            ),

            if (_notifications.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFFF8FAFC),
                alignment: Alignment.center,
                child: Text(
                  '${_notifications.length} notification${_notifications.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFAABBC8)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onMarkRead;
  const _NotificationRow({required this.n, required this.onMarkRead});

  ({Color fg, Color bg, IconData icon}) get _style {
    if (n.type.contains('approved')) return (fg: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7), icon: Icons.check);
    if (n.type.contains('rejected')) return (fg: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2), icon: Icons.close);
    if (n.type.contains('removed')) return (fg: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7), icon: Icons.delete_outline);
    if (n.type.contains('reschedule') || n.type.contains('updated')) {
      return (fg: const Color(0xFF2D4A5A), bg: const Color(0xFFE8F4FD), icon: Icons.sync);
    }
    return (fg: const Color(0xFF2D4A5A), bg: const Color(0xFFE8F4FD), icon: Icons.event_note_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : const Color(0xFFF5F9FF),
        border: const Border(bottom: BorderSide(color: Color(0xFFF0F4F7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(s.icon, size: 15, color: s.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: TextStyle(fontSize: 12, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, color: const Color(0xFF1A2E3A), height: 1.3)),
                const SizedBox(height: 3),
                Text(n.message, style: const TextStyle(fontSize: 11, color: Color(0xFF5A7080), height: 1.4)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(n.timeAgo, style: const TextStyle(fontSize: 10, color: Color(0xFFAABBC8))),
                    if (!n.isRead) ...[
                      const SizedBox(width: 6),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!n.isRead)
            IconButton(
              icon: const Icon(Icons.check, size: 15, color: Color(0xFF4A7A93)),
              onPressed: onMarkRead,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Mark as read',
            ),
        ],
      ),
    );
  }
}