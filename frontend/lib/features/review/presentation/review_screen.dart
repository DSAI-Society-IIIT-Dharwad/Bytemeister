import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/review_state.dart';
import 'review_notifier.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(reviewNotifierProvider.notifier)
          .setWorkflow(WorkflowType.healthcare),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewNotifierProvider);
    final notifier = ref.read(reviewNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final isHealthcare = state.workflowType == WorkflowType.healthcare;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Report'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<WorkflowType>(
                value: state.workflowType,
                onChanged: (WorkflowType? newValue) {
                  if (newValue != null) notifier.setWorkflow(newValue);
                },
                items: WorkflowType.values.map<DropdownMenuItem<WorkflowType>>((
                  WorkflowType value,
                ) {
                  return DropdownMenuItem<WorkflowType>(
                    value: value,
                    child: Text(
                      value.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: state.isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('Securing your data...', style: textTheme.bodyMedium),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: _ReportHeader(
                      workflowType: state.workflowType,
                      isHealthcare: isHealthcare,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entity = state.entities[index];
                      return _EntityCard(
                        entity: entity,
                        onChanged: (val) => notifier.updateEntity(index, val),
                        onToggleVerify: () => notifier.toggleVerified(index),
                        primaryColor: isHealthcare
                            ? AppColors.healthcarePrimary
                            : AppColors.financePrimary,
                      );
                    }, childCount: state.entities.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            await notifier.submit();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Interaction verified and archived.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isHealthcare
                ? AppColors.healthcarePrimary
                : AppColors.financePrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_outlined, size: 20),
              SizedBox(width: 12),
              Text('Finalise & Archive'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final WorkflowType workflowType;
  final bool isHealthcare;

  const _ReportHeader({required this.workflowType, required this.isHealthcare});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = isHealthcare
        ? AppColors.healthcarePrimary
        : AppColors.financePrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHealthcare
                    ? Icons.medical_services_outlined
                    : Icons.account_balance_outlined,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isHealthcare
                    ? 'CLINICAL DOCUMENTATION'
                    : 'FINANCIAL CONFIRMATION',
                style: textTheme.labelLarge?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isHealthcare
                ? 'Automated Visit Summary'
                : 'Interaction Audit Report',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Extracted from live audio stream. Please verify the accuracy of each field.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  final dynamic entity;
  final Function(String) onChanged;
  final VoidCallback onToggleVerify;
  final Color primaryColor;

  const _EntityCard({
    required this.entity,
    required this.onChanged,
    required this.onToggleVerify,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entity.isVerified
              ? primaryColor.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entity.key.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${(entity.confidence * 100).toStringAsFixed(0)}% Match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: entity.confidence > 0.8
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: entity.isVerified,
                        onChanged: (_) => onToggleVerify(),
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextFormField(
              initialValue: entity.value,
              onChanged: onChanged,
              maxLines: null,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                fillColor: AppColors.background,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
