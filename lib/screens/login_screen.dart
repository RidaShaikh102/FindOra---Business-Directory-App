import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:findora/providers/auth_form_providers.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_layout.dart';
import 'role_gate.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const Color primaryColor = Color(0xFF137B75);
  static const Color secondaryColor = Color(0xFF003049);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('LoginScreen');
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    ref.read(loginFormProvider.notifier).setLoading(true);

    try {
      final success = await AuthService().login(email, password);
      if (!mounted) return;

      if (success) {
        await AnalyticsService.logAction('login');
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleGate()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        ref.read(loginFormProvider.notifier).setLoading(false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    ref.read(loginFormProvider.notifier).setLoading(true);

    try {
      final success = await AuthService().signInWithGoogle();
      if (!mounted) return;

      if (success) {
        await AnalyticsService.logAction('login_google');
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleGate()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google sign-in failed.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        ref.read(loginFormProvider.notifier).setLoading(false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: secondaryColor),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleFontSize = MediaQuery.textScalerOf(context).scale(28);
    final isWideLayout = screenWidth >= 900;
    final horizontalPadding = screenWidth >= 600 ? 32.0 : 24.0;
    final verticalPadding = isWideLayout ? 36.0 : 60.0;

    final brandHeader = Column(
      crossAxisAlignment: isWideLayout
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Image.asset('lib/assets/logo.png', height: 60),
        ),
        const SizedBox(height: 10),
        Text(
          'FindOra',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
          textAlign: isWideLayout ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: isWideLayout ? 28 : 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: isWideLayout ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Log in to explore businesses, manage services, and pick up where you left off.',
          style: TextStyle(
            fontSize: isWideLayout ? 16 : 14,
            height: 1.5,
            color: Colors.blueGrey.shade700,
          ),
          textAlign: isWideLayout ? TextAlign.left : TextAlign.center,
        ),
      ],
    );

    final formCard = Container(
      padding: EdgeInsets.all(isWideLayout ? 28 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email', Icons.email),
              validator: (value) => value != null && value.contains('@')
                  ? null
                  : 'Enter a valid email',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: formState.obscurePassword,
              decoration: _inputDecoration('Password', Icons.lock).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    formState.obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      ref.read(loginFormProvider.notifier).toggleObscure(),
                ),
              ),
              validator: (value) => value != null && value.length >= 6
                  ? null
                  : 'Password must be at least 6 characters',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: formState.isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: formState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: formState.isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata, color: secondaryColor),
              label: const Text(
                'Continue with Google',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: secondaryColor),
                foregroundColor: secondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (verticalPadding * 2),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideLayout ? 980 : 520,
                    ),
                    child: isWideLayout
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 32),
                                  child: brandHeader,
                                ),
                              ),
                              Expanded(
                                child: ResponsivePanelCard(child: formCard),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              brandHeader,
                              const SizedBox(height: 30),
                              formCard,
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
