import 'package:flutter/material.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/config/app_config.dart';
import 'package:findora/services/analytics_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final list = await _authService.getUsers();
    setState(() {
      _users = list;
      _loading = false;
    });
  }

  Future<void> _toggleBlock(int index) async {
    final user = Map<String, dynamic>.from(_users[index]);
    user['isBlocked'] = !(user['isBlocked'] == true);
    _users[index] = user;
    await _authService.saveUsers(_users);
    await AnalyticsService.logAction(
      user['isBlocked'] == true ? 'user_blocked' : 'user_unblocked',
    );
    if (mounted) setState(() {});
  }

  Future<void> _changeRole(int index, String role) async {
    final user = Map<String, dynamic>.from(_users[index]);
    final email = user['email'] ?? '';
    if (role == 'super_admin' && email != superAdminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only allowed email can be Super Admin.')),
      );
      return;
    }
    user['role'] = role;
    _users[index] = user;
    await _authService.saveUsers(_users);
    await AnalyticsService.logAction('user_role_changed_$role');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final role = user['role'] ?? 'user';
        final blocked = user['isBlocked'] == true;
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.teal, width: 1),
          ),
          child: ListTile(
            title: Text(user['email'] ?? 'Unknown'),
            subtitle: Text('Role: $role\nBlocked: ${blocked ? 'Yes' : 'No'}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  _toggleBlock(index);
                } else {
                  _changeRole(index, value);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'user', child: Text('Set User')),
                PopupMenuItem(value: 'owner', child: Text('Set Owner')),
                PopupMenuItem(
                  value: 'super_admin',
                  child: Text('Set Super Admin'),
                ),
                PopupMenuItem(value: 'block', child: Text('Block/Unblock')),
              ],
            ),
          ),
        );
      },
    );
  }
}
