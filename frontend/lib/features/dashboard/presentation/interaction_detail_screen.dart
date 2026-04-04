import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/interaction.dart';
import '../presentation/dashboard_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/theme_provider.dart';

class InteractionDetailScreen extends ConsumerWidget {
  final Interaction interaction;

  const InteractionDetailScreen({super.key, required this.interaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          final dashboardState = ref.read(dashboardNotifierProvider);
          final themeNotifier = ref.read(themeNotifierProvider.notifier);
          
          if (dashboardState.selectedDomain == 'Healthcare') {
            themeNotifier.setHealthcare();
          } else if (dashboardState.selectedDomain == 'Finance') {
            themeNotifier.setFinance();
          } else {
            themeNotifier.setStandard();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(interaction.domainType),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          interaction.domainType == 'Healthcare'
                              ? Icons.medical_services
                              : Icons.account_balance_wallet,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMMM d, yyyy • h:mm a').format(interaction.date),
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      interaction.summary,
                      style: textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('TRANSCRIPT', style: textTheme.labelLarge),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  interaction.transcript,
                  style: textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 32),
              Text('KEY DETAILS', style: textTheme.labelLarge),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  interaction.details,
                  style: textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Action to verify or edit
                  },
                  child: const Text('Verify Information'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
