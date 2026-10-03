import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// Pixel-matched to frontend/src/pages/LoginPage.js + the
/// .login-page / .login-card / .login-form rules in index.css.
class _LC {
  static const primary = Color(0xFF2D4A5A);
  static const accent = Color(0xFF4A90D9);
  static const border = Color(0xFFA9BAC4); // darker/more visible than before
  static const textSecondary = Color(0xFF5A7080);
  static const textMuted = Color(0xFF8FA5B0);
  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerBorder = Color(0xFFFECACA);
  static const dangerText = Color(0xFFDC2626);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPwd = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final id = _idController.text.trim();
    final pwd = _passwordController.text;
    if (id.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    final auth = context.read<AuthProvider>();
    try {
      final user = await auth.login(id, pwd);
      if (!mounted) return;
      if (!user.isTeacher && !user.isStudent) {
        await auth.logout();
        setState(() => _error = 'This app only supports Teacher and Student accounts.');
      }
      // Otherwise the root router in main.dart swaps screens automatically.
    } catch (_) {
      setState(() => _error = auth.error ?? 'Invalid JUW ID or password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2E3A), Color(0xFF2D4A5A), Color(0xFF3D6678)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: 390,
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Academic Scheduler Agent',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _LC.primary),
                    ),
                    const SizedBox(height: 26),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                        decoration: BoxDecoration(
                          color: _LC.dangerBg,
                          border: Border.all(color: _LC.dangerBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: const TextStyle(color: _LC.dangerText, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _FieldLabel('JUW ID'),
                    const SizedBox(height: 5),
                    _LoginTextField(
                      controller: _idController,
                      hintText: 'e.g. T001 or JUW ID',
                      autofocus: true,
                    ),
                    const SizedBox(height: 15),
                    _FieldLabel('Password'),
                    const SizedBox(height: 5),
                    _LoginTextField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      obscureText: !_showPwd,
                      suffix: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 17,
                          color: _LC.textMuted,
                        ),
                        onPressed: () => setState(() => _showPwd = !_showPwd),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _LC.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _LC.primary.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login, size: 16),
                              SizedBox(width: 8),
                              Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _LC.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _LoginTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool autofocus;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const _LoginTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.autofocus = false,
    this.suffix,
    this.onSubmitted,
  });

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _focused ? _LC.accent : _LC.border, width: _focused ? 1.6 : 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          autofocus: widget.autofocus,
          onSubmitted: widget.onSubmitted,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A2E3A)),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(fontSize: 13.5, color: _LC.textMuted),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            border: InputBorder.none,
            suffixIcon: widget.suffix == null
                ? null
                : Padding(padding: const EdgeInsets.only(right: 10), child: widget.suffix),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      ),
    );
  }
}