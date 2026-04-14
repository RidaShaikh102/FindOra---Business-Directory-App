import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import '../services/analytics_service.dart';
import 'login_screen.dart';
import 'role_gate.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'user';

  // Null-safe booleans
  bool _isLoading = false;
  bool _obscurePassword = true;
  double _passwordStrength = 0.0;

  // Colors
  static const Color primaryColor = Color(0xFF137B75);
  static const Color secondaryColor = Color(0xFF003049);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('SignupScreen');
  }

  void _checkPasswordStrength(String value) {
    double strength = 0.0;
    if (value.length >= 6) strength += 0.3;
    if (RegExp(r"[0-9]").hasMatch(value)) strength += 0.3;
    if (RegExp(r"[A-Z]").hasMatch(value)) strength += 0.4;
    setState(() => _passwordStrength = strength.clamp(0.0, 1.0));
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email == superAdminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Super Admin is already created. Please log in."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final success = await authService.signup(
        email,
        password,
        name,
        role: _selectedRole,
      );
      if (success) {
        await AnalyticsService.logAction('signup');
        await authService.login(email, password);
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleGate()),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Signup failed. Please check your details or try another email.",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 120,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        width: 50,
                        color: secondaryColor,
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                      ),
                      const SizedBox(height: 24),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                "Name",
                                Icons.person,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? "Enter your name"
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration(
                                "Email",
                                Icons.email,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  value != null && value.contains("@")
                                  ? null
                                  : "Enter a valid email",
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: _inputDecoration("Role", Icons.badge),
                              items: const [
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text('User'),
                                ),
                                DropdownMenuItem(
                                  value: 'owner',
                                  child: Text('Owner'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedRole = value);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: _checkPasswordStrength,
                              decoration:
                                  _inputDecoration(
                                    "Password",
                                    Icons.lock,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                              validator: (value) =>
                                  value != null && value.length >= 6
                                  ? null
                                  : "Password must be at least 6 characters",
                            ),
                            const SizedBox(height: 8),

                            // Password strength
                            LinearProgressIndicator(
                              value: _passwordStrength,
                              backgroundColor: Colors.grey[300],
                              minHeight: 6,
                              color: _passwordStrength < 0.4
                                  ? Colors.red
                                  : _passwordStrength < 0.7
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _passwordStrength < 0.4
                                  ? "Weak password"
                                  : _passwordStrength < 0.7
                                  ? "Medium strength"
                                  : "Strong password",
                              style: TextStyle(
                                fontSize: 12,
                                color: _passwordStrength < 0.4
                                    ? Colors.red
                                    : _passwordStrength < 0.7
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Signup button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),

                            // Login redirect
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                                child: const Text(
                                  "Already have an account? Login",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
