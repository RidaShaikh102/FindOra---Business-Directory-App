import 'package:flutter/material.dart';

import 'package:findora/screens/add_business_screen.dart';
import 'package:findora/screens/owner/manage_orders_screen.dart';
import 'package:findora/screens/user_review_screen.dart';
import 'package:findora/screens/your_businesses.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/local_storage_service.dart';
import 'package:findora/widgets/responsive_layout.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _businessCount = 0;
  int _orderCount = 0;
  int _pendingOrderCount = 0;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
    AnalyticsService.logScreenView('OwnerDashboard');
  }

  Future<void> _loadStats() async {
    final authService = AuthService();
    final email = await authService.getCurrentUserEmail() ?? '';
    final storage = LocalStorageService();
    final businesses = await storage.getBusinessesByOwner(email);
    final orders = await storage.getOrdersForOwner(email);

    if (!mounted) return;
    setState(() {
      _email = email;
      _businessCount = businesses.length;
      _orderCount = orders.length;
      _pendingOrderCount = orders
          .where((order) => order['status'] == 'pending')
          .length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Center(
        child: ResponsivePageContainer(
          maxWidth: 1200,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0A2D3F),
                        const Color(0xFF0A2D3F).withValues(alpha: 0.9),
                        Colors.teal.shade700,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.dashboard_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Owner Panel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _pendingOrderCount > 0
                                          ? '$_pendingOrderCount order(s) waiting for action'
                                          : 'Manage your businesses and orders',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = ResponsiveLayout.adaptiveGridCount(
                          context,
                          compact: 2,
                          medium: 3,
                          expanded: 4,
                        );
                        final spacing = 12.0;
                        final cardWidth =
                            (constraints.maxWidth - ((columns - 1) * spacing)) /
                            columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _buildStatCard(
                                'My Businesses',
                                _businessCount.toString(),
                                Icons.store_rounded,
                                Colors.teal.shade700,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _buildStatCard(
                                'All Orders',
                                _orderCount.toString(),
                                Icons.shopping_bag_rounded,
                                Colors.blue.shade700,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _buildStatCard(
                                'Pending',
                                _pendingOrderCount.toString(),
                                Icons.pending_actions_rounded,
                                Colors.orange.shade700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Quick actions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _buildActionCard(
                      label: 'Manage Orders',
                      subtitle: 'Confirm, track, and complete customer orders',
                      icon: Icons.receipt_long_rounded,
                      iconColor: Colors.orange.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageOrdersScreen(),
                          ),
                        ).then((_) => _loadStats());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      label: 'Add Business',
                      subtitle: 'Register a new business',
                      icon: Icons.add_business_rounded,
                      iconColor: Colors.teal.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddBusinessScreen(),
                          ),
                        ).then((_) => _loadStats());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      label: 'Your Businesses',
                      subtitle: 'View and edit your listings',
                      icon: Icons.store_rounded,
                      iconColor: Colors.teal.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                YourBusinessesScreen(userEmail: _email),
                          ),
                        ).then((_) => _loadStats());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      label: 'Business Reviews',
                      subtitle: 'See what customers say',
                      icon: Icons.reviews_rounded,
                      iconColor: Colors.teal.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserReviewsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
