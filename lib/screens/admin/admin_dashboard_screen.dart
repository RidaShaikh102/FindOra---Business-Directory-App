import 'package:flutter/material.dart';
import 'package:findora/services/analytics_service.dart';
import 'package:findora/services/auth_service.dart';
import 'package:findora/services/local_storage_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _businessCount = 0;
  int _reviewCount = 0;
  int _userCount = 0;
  int _trafficCount = 0;
  List<MapEntry<String, int>> _topScreens = [];
  List<MapEntry<String, int>> _topActions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final storage = LocalStorageService();
    final auth = AuthService();
    final businesses = await storage.getBusinesses();
    final reviews = await storage.getReviews();
    final users = await auth.getUsers();
    final traffic = await AnalyticsService.getAppOpens();
    final screens = await AnalyticsService.getScreenViews();
    final actions = await AnalyticsService.getActions();

    final screenList = screens.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final actionList = actions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (!mounted) return;
    setState(() {
      _businessCount = businesses.length;
      _reviewCount = reviews.length;
      _userCount = users.length;
      _trafficCount = traffic;
      _topScreens = screenList.take(5).toList();
      _topActions = actionList.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FB),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: Colors.teal.shade700,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats grid 2x2
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Businesses',
                        _businessCount.toString(),
                        Icons.store_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Reviews',
                        _reviewCount.toString(),
                        Icons.rate_review_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Users',
                        _userCount.toString(),
                        Icons.people_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'App Opens',
                        _trafficCount.toString(),
                        Icons.show_chart_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Top Screen Views - visual analytics
                _buildSectionLabel('Top Screen Views'),
                const SizedBox(height: 12),
                _buildAnalyticsCard(
                  items: _topScreens,
                  emptyMessage: 'No screen views yet.',
                  icon: Icons.visibility_rounded,
                ),
                const SizedBox(height: 24),

                // Top Actions - visual analytics
                _buildSectionLabel('Top Actions'),
                const SizedBox(height: 12),
                _buildAnalyticsCard(
                  items: _topActions,
                  emptyMessage: 'No actions yet.',
                  icon: Icons.touch_app_rounded,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              color: Colors.teal.shade700.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.teal.shade700, size: 24),
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
              color: Colors.teal.shade700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required List<MapEntry<String, int>> items,
    required String emptyMessage,
    required IconData icon,
  }) {
    final maxVal = items.isEmpty
        ? 1
        : items.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Text(
                    emptyMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    _buildAnalyticsRow(
                      rank: i + 1,
                      label: items[i].key,
                      value: items[i].value,
                      maxValue: maxVal,
                    ),
                    if (i < items.length - 1)
                      Divider(height: 1, color: Colors.grey.shade200),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyticsRow({
    required int rank,
    required String label,
    required int value,
    required int maxValue,
  }) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.teal.shade700.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatLabel(label),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    if (key.isEmpty) return key;
    final normalized = key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        );
    return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
  }
}
