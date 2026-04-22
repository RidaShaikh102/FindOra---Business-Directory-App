import 'package:flutter/material.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/screens/login_screen.dart';
import 'package:findora/screens/change_password_dialog.dart';
import 'package:findora/services/analytics_service.dart';
import 'admin_dashboard_screen.dart';
import 'manage_businesses_screen.dart';
import 'manage_claims_screen.dart';
import 'manage_reviews_screen.dart';
import 'manage_users_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    ManageBusinessesScreen(),
    ManageClaimsScreen(),
    ManageReviewsScreen(),
    ManageUsersScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded),
    _NavItem(label: 'Businesses', icon: Icons.store_rounded),
    _NavItem(label: 'Claims', icon: Icons.how_to_reg_rounded),
    _NavItem(label: 'Reviews', icon: Icons.rate_review_rounded),
    _NavItem(label: 'Users', icon: Icons.people_rounded),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('AdminDashboard');
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    final name = index == 0
        ? 'AdminDashboard'
        : index == 1
        ? 'AdminBusinesses'
        : index == 2
        ? 'AdminClaims'
        : index == 3
        ? 'AdminReviews'
        : 'AdminUsers';
    AnalyticsService.logScreenView(name);
  }

  Future<void> _showChangePassword() async {
    final messenger = ScaffoldMessenger.of(context);
    await showChangePasswordDialog(context, (oldPass, newPass) async {
      final email = await AuthService().getCurrentUserEmail() ?? '';
      final success = await AuthService().changePassword(
        email,
        oldPass,
        newPass,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Password updated successfully'
                : 'Old password is incorrect',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    });
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentNav = _navItems[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          // Gradient header (like owner panel)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A2D3F),
                  const Color(0xFF0A2D3F).withOpacity(0.9),
                  Colors.teal.shade700,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            currentNav.icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Super Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentNav.label,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Change Password',
                          onPressed: _showChangePassword,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Logout',
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SizedBox.expand(child: _screens[_selectedIndex]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _NavTile(
                  item: _navItems[index],
                  isSelected: _selectedIndex == index,
                  onTap: () => _onItemTapped(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem({required this.label, required this.icon});
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.teal.shade700.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: isSelected ? Colors.teal.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.teal.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
