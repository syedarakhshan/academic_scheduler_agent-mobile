import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../common/notifications_sheet.dart';
import '../common/profile_settings_dialog.dart';
import 'student_courses_screen.dart';
import 'student_dashboard_screen.dart';
import 'student_timetable_screen.dart';

/// Mirrors the student NAV array in frontend/src/pages/student/StudentDashboard.js:
///   Dashboard, Timetable, My Courses — with the same notification
/// bell, Profile Settings, and logout confirmation as the teacher shell.
class StudentHomeShell extends StatefulWidget {
  const StudentHomeShell({super.key});

  @override
  State<StudentHomeShell> createState() => _StudentHomeShellState();
}

class _StudentHomeShellState extends State<StudentHomeShell> {
  int _index = 0;
  int _unreadCount = 0;

  static const _tabs = [
    _TabDef('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _TabDef('Timetable', Icons.calendar_today_outlined, Icons.calendar_today),
    _TabDef('My Courses', Icons.menu_book_outlined, Icons.menu_book),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final list = await NotificationService.instance.getNotifications();
      if (!mounted) return;
      setState(() => _unreadCount = list.where((n) => !n.isRead).length);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    final changed = await NotificationsSheet.show(context);
    if (changed == true) _loadUnreadCount();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Log out?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(fontSize: 13)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF5A7080))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].label),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _openNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Profile Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => ProfileSettingsDialog.show(context),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: switch (_index) {
        0 => const StudentDashboardScreen(),
        1 => const StudentTimetableScreen(),
        _ => const StudentCoursesScreen(),
      },
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navy,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.outline), selectedIcon: Icon(t.filled), label: t.label),
        ],
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData outline;
  final IconData filled;
  const _TabDef(this.label, this.outline, this.filled);
}