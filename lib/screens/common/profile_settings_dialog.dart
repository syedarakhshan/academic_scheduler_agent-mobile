import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Mirrors ProfileModal.js — Profile / Change Password / Security tabs.
class ProfileSettingsDialog extends StatefulWidget {
  const ProfileSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ProfileSettingsDialog(),
    );
  }

  @override
  State<ProfileSettingsDialog> createState() => _ProfileSettingsDialogState();
}

class _ProfileSettingsDialogState extends State<ProfileSettingsDialog> {
  int _tab = 0;
  static const _tabs = [
    (label: 'Profile', icon: Icons.person_outline),
    (label: 'Change Password', icon: Icons.lock_outline),
    (label: 'Security', icon: Icons.shield_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: const BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 17, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Manage your account', style: TextStyle(fontSize: 11, color: Colors.white60)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 15, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15), padding: const EdgeInsets.all(6)),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),

            // ── Tab bar ─────────────────────────────────────────
            Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: _tab == i ? AppColors.navy : Colors.transparent, width: 2)),
                        ),
                        child: Column(
                          children: [
                            Icon(_tabs[i].icon, size: 14, color: _tab == i ? AppColors.navy : const Color(0xFF7A9AAA)),
                            const SizedBox(height: 3),
                            Text(
                              _tabs[i].label,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500, color: _tab == i ? AppColors.navy : const Color(0xFF7A9AAA)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 1),

            // ── Content ───────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: switch (_tab) {
                  0 => const _ProfileTab(),
                  1 => const _PasswordTab(),
                  _ => const _SecurityTab(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final roleLabel = user?.role == 'teacher' ? 'Teacher' : 'Student';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE0E8ED)), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.navy,
                child: Text(user?.initials ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2E3A))),
                    const SizedBox(height: 3),
                    Text(user?.juwId ?? '', style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A9AAA))),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFE8F4FD), border: Border.all(color: const Color(0xFFB8D9F5)), borderRadius: BorderRadius.circular(8)),
                      child: Text(roleLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A5A7A))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.person_outline, label: 'Full Name', value: user?.fullName ?? '—'),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.badge_outlined, label: 'JUW ID', value: user?.juwId ?? '—'),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.shield_outlined, label: 'Role', value: roleLabel),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), border: Border.all(color: const Color(0xFFBFDBFE)), borderRadius: BorderRadius.circular(8)),
          child: const Text('To update your profile details, contact the system administrator.', style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF))),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE0E8ED)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: const Color(0xFFF0F6FA), borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 14, color: AppColors.navy),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF7A9AAA), letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1A2E3A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordTab extends StatefulWidget {
  const _PasswordTab();

  @override
  State<_PasswordTab> createState() => _PasswordTabState();
}

class _PasswordTabState extends State<_PasswordTab> {
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false, _showNew = false, _showConfirm = false;
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  ({int score, String label, Color color}) get _strength {
    final p = _newPass.text;
    if (p.isEmpty) return (score: 0, label: '', color: const Color(0xFFE0E8ED));
    var s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) s++;
    const map = [
      (label: 'Too short', color: Color(0xFFEF4444)),
      (label: 'Weak', color: Color(0xFFEF4444)),
      (label: 'Fair', color: Color(0xFFF59E0B)),
      (label: 'Good', color: Color(0xFF3B82F6)),
      (label: 'Strong', color: Color(0xFF22C55E)),
      (label: 'Very Strong', color: Color(0xFF16A34A)),
    ];
    final m = map[s.clamp(0, map.length - 1)];
    return (score: s, label: m.label, color: m.color);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_current.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    if (_newPass.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (_newPass.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().changePassword(_current.text, _newPass.text);
      if (!mounted) return;
      setState(() {
        _success = true;
        _loading = false;
      });
      _current.clear();
      _newPass.clear();
      _confirm.clear();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _success = false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to change password.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 26, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 14),
            const Text('Password Changed!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
            const SizedBox(height: 6),
            const Text('Your password has been updated successfully.', style: TextStyle(fontSize: 12.5, color: Color(0xFF7A9AAA))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PwField(label: 'Current Password', controller: _current, show: _showCurrent, onToggle: () => setState(() => _showCurrent = !_showCurrent), hint: 'Enter current password'),
        const SizedBox(height: 12),
        _PwField(label: 'New Password', controller: _newPass, show: _showNew, onToggle: () => setState(() => _showNew = !_showNew), hint: 'At least 6 characters', onChanged: () => setState(() {})),
        if (_newPass.text.isNotEmpty) ...[
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: _strength.score / 5, backgroundColor: const Color(0xFFE0E8ED), color: _strength.color, minHeight: 4),
          ),
          const SizedBox(height: 3),
          Text(_strength.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _strength.color)),
        ],
        const SizedBox(height: 12),
        _PwField(label: 'Confirm New Password', controller: _confirm, show: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm), hint: 'Re-enter new password', onChanged: () => setState(() {})),
        if (_confirm.text.isNotEmpty && _newPass.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(_newPass.text == _confirm.text ? Icons.check : Icons.close, size: 11, color: _newPass.text == _confirm.text ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text(
                _newPass.text == _confirm.text ? 'Passwords match' : 'Passwords do not match',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _newPass.text == _confirm.text ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
              ),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(7)),
            child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_outline, size: 14),
            label: Text(_loading ? 'Updating...' : 'Update Password', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
          ),
        ),
      ],
    );
  }
}

class _PwField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggle;
  final String hint;
  final VoidCallback? onChanged;
  const _PwField({required this.label, required this.controller, required this.show, required this.onToggle, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5A7080), letterSpacing: 0.4)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: !show,
          onChanged: (_) => onChanged?.call(),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFDDE3E8))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFDDE3E8))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 1.5)),
            suffixIcon: IconButton(
              icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16, color: const Color(0xFF7A9AAA)),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final items = [
      (label: 'Last Login', value: 'This session', icon: Icons.access_time),
      (label: 'Account Status', value: 'Active', icon: Icons.bolt_outlined),
      (label: 'Role', value: user?.role ?? '', icon: Icons.shield_outlined),
      (label: 'Password Policy', value: 'Min 6 characters with mixed characters', icon: Icons.vpn_key_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE0E8ED)), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: const Color(0xFFE8F4FD), borderRadius: BorderRadius.circular(6)),
                  child: Icon(item.icon, size: 12, color: AppColors.navy),
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(item.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF5A7080)))),
                Flexible(
                  child: Text(
                    item.value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFF92400E)),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.5),
                    children: [
                      TextSpan(text: 'Security Tips: ', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: 'Use a strong password with uppercase letters, numbers and symbols. Never share your credentials with anyone.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}