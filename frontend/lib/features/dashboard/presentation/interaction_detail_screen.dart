import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/interaction.dart';
import '../presentation/dashboard_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/providers/theme_provider.dart';

class InteractionDetailScreen extends ConsumerStatefulWidget {
  final Interaction interaction;

  const InteractionDetailScreen({super.key, required this.interaction});

  @override
  ConsumerState<InteractionDetailScreen> createState() =>
      _InteractionDetailScreenState();
}

class _InteractionDetailScreenState
    extends ConsumerState<InteractionDetailScreen> {
  late TextEditingController _transcriptController;
  late TextEditingController _detailsController;
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _transcriptController =
        TextEditingController(text: widget.interaction.transcript);
    _detailsController =
        TextEditingController(text: widget.interaction.details);
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitCorrection() async {
    setState(() => _isSaving = true);

    final client = ref.read(memoryLayerClientProvider);
    final success = await client.updateRecord(
      widget.interaction.id,
      correctedTranscript: _transcriptController.text,
      correctedExtraction: {
        'plain_summary': widget.interaction.summary,
        'corrected_fields': _detailsController.text,
      },
    );

    setState(() {
      _isSaving = false;
      _saved = success;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Correction saved to Secure Memory.'
              : '⚠️ Memory Layer offline — correction not persisted.'),
          backgroundColor:
              success ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isHealthcare = widget.interaction.domainType == 'Healthcare';
    final accentColor = isHealthcare
        ? AppColors.healthcarePrimary
        : AppColors.financePrimary;

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
          title: Text(widget.interaction.domainType),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.interaction.status == InteractionStatus.verified
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.interaction.status == InteractionStatus.verified
                    ? 'Verified'
                    : 'Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.interaction.status == InteractionStatus.verified
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHealthcare
                              ? Icons.medical_services
                              : Icons.account_balance_wallet,
                          color: accentColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMMM d, yyyy • h:mm a')
                              .format(widget.interaction.date),
                          style: textTheme.labelLarge?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.interaction.summary,
                      style: textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Human Correction notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded,
                        size: 18, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Human-in-the-loop correction — edits below are submitted to the Secure Memory Layer via PUT /update-record.',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Editable transcript
              _SectionLabel(label: 'TRANSCRIPT', color: accentColor),
              const SizedBox(height: 10),
              TextFormField(
                controller: _transcriptController,
                maxLines: null,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: 'Conversation transcript…',
                  fillColor: AppColors.surface,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: textTheme.bodyLarge?.copyWith(height: 1.6),
              ),

              const SizedBox(height: 24),

              // Editable details / key findings
              _SectionLabel(label: 'KEY DETAILS', color: accentColor),
              const SizedBox(height: 10),
              TextFormField(
                controller: _detailsController,
                maxLines: null,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Key findings, advice, next steps…',
                  fillColor: AppColors.surface,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: textTheme.bodyLarge?.copyWith(height: 1.6),
              ),

              const SizedBox(height: 36),

              // Submit button → PUT /update-record
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitCorrection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Submit Correction',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                )),
      ],
    );
  }
}
