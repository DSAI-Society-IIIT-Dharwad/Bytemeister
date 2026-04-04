import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../voice/presentation/voice_screen.dart';
import '../../chat/presentation/chat_screen.dart';
import '../domain/interaction.dart';
import 'dashboard_notifier.dart';
import 'interaction_detail_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final filteredInteractions = state.selectedDomain == 'All'
        ? state.interactions
        : state.interactions
            .where((i) => i.domainType == state.selectedDomain)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good Morning, User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AnalyticsSheet(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'All',
                    label: Text('All'),
                    icon: Icon(Icons.apps_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'Healthcare',
                    label: Text('Medical'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'Finance',
                    label: Text('Financial'),
                    icon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ],
                selected: {state.selectedDomain},
                onSelectionChanged: (newSelection) {
                  final domain = newSelection.first;
                  ref.read(dashboardNotifierProvider.notifier).setSelectedDomain(domain);
                  
                  // Update App Theme
                  final themeNotifier = ref.read(themeNotifierProvider.notifier);
                  if (domain == 'Healthcare') {
                    themeNotifier.setHealthcare();
                  } else if (domain == 'Finance') {
                    themeNotifier.setFinance();
                  } else {
                    themeNotifier.setStandard();
                  }
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: colorScheme.primary,
                  selectedForegroundColor: colorScheme.onPrimary,
                  side: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                children: [
                  _StatCard(
                    label: 'Total',
                    value: filteredInteractions.length.toString(),
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Verified',
                    value: filteredInteractions
                        .where((i) => i.status == InteractionStatus.verified)
                        .length
                        .toString(),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Pending',
                    value: filteredInteractions
                        .where((i) => i.status == InteractionStatus.pending)
                        .length
                        .toString(),
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                state.selectedDomain == 'All' ? 'RECENT INTERACTIONS' : '${state.selectedDomain.toUpperCase()} INTERACTIONS', 
                style: textTheme.labelLarge
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final interaction = filteredInteractions[index];
                final isHealthcare = interaction.domainType == 'Healthcare';
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      if (isHealthcare) {
                        ref.read(themeNotifierProvider.notifier).setHealthcare();
                      } else {
                        ref.read(themeNotifierProvider.notifier).setFinance();
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InteractionDetailScreen(
                            interaction: interaction,
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isHealthcare
                            ? AppColors.healthcareSurface
                            : AppColors.financeSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isHealthcare
                            ? Icons.medical_services_outlined
                            : Icons.account_balance_wallet_outlined,
                        color: isHealthcare
                            ? AppColors.healthcarePrimary
                            : AppColors.financePrimary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      interaction.summary,
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${DateFormat('MMM d, h:mm a').format(interaction.date)} • ${interaction.domainType}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: interaction.status == InteractionStatus.verified
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        interaction.status == InteractionStatus.verified
                            ? 'Verified'
                            : 'Pending',
                        style: TextStyle(
                          color: interaction.status == InteractionStatus.verified
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: state.interactions.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartActionSheet(context),
        label: const Text('New Interaction'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.surface,
      ),
    );
  }

  void _showStartActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Start New Interaction',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            _ActionTile(
              title: 'Voice Session',
              subtitle: 'Hands-free multilingual capture',
              icon: Icons.mic_none_outlined,
              color: AppColors.healthcarePrimary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const VoiceScreen()));
              },
            ),
            const SizedBox(height: 12),
            _ActionTile(
              title: 'Chat Assistant',
              subtitle: 'Guided interactive documentation',
              icon: Icons.chat_bubble_outline,
              color: AppColors.financePrimary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()));
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class AnalyticsSheet extends StatelessWidget {
  const AnalyticsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Activity Overview',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Interaction volume over the last week',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final index = (value / 2).toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[index], style: Theme.of(context).textTheme.labelLarge),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: Theme.of(context).textTheme.labelLarge);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppColors.textPrimary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} Sessions',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(2, 2.5),
                      FlSpot(4, 5),
                      FlSpot(6, 3.5),
                      FlSpot(8, 4),
                      FlSpot(10, 3),
                      FlSpot(12, 4.5),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: [AppColors.healthcarePrimary, AppColors.financePrimary],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppColors.healthcarePrimary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.healthcarePrimary.withValues(alpha: 0.2),
                          AppColors.financePrimary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
