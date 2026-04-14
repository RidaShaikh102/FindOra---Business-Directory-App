import 'package:flutter/material.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/screens/admin/admin_main_screen.dart';
import 'package:findora/screens/main_shell.dart';
import 'package:findora/screens/login_screen.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        final role = snapshot.data ?? 'user';
        if (role == 'super_admin') {
          return const AdminMainScreen();
        }
        return MainScreen(userRole: role);
      },
    );
  }
}
