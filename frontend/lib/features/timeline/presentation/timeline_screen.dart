import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'timeline_notifier.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final TextEditingController _userIdController =
      TextEditingController(text: 'Rahul_Dr._Smith');

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Longitudinal Timeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            tooltip: 'Change User ID',
            onPressed: () => _showUserIdDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // User ID header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.healthcareSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timeline,
                      color: AppColors.healthcarePrimary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VIEWING TIMELINE FOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        state.userId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: () =>
                        ref.read(timelineNotifierProvider.notifier).loadTimeline(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Timeline body
          Expanded(
            child: _buildTimeline(state, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(TimelineState state, TextTheme textTheme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null || state.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_toggle_off_outlined,
                    size: 40, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Timeline Entries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error ??
                    'No chronological records found for this user.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: state.entries.length,
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        final isLast = index == state.entries.length - 1;
        return _TimelineEntry(
          entry: entry,
          index: index,
          isLast: isLast,
        );
      },
    );
  }

  void _showUserIdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change User ID'),
        content: TextField(
          controller: _userIdController,
          decoration: const InputDecoration(
            hintText: 'e.g. Rahul_Dr._Smith',
            labelText: 'User ID',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(timelineNotifierProvider.notifier)
                  .loadTimeline(_userIdController.text.trim());
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends ConsumerStatefulWidget {
  final Map<String, dynamic> entry;
  final int index;
  final bool isLast;

  const _TimelineEntry({
    required this.entry,
    required this.index,
    required this.isLast,
  });

  @override
  ConsumerState<_TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends ConsumerState<_TimelineEntry> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final domain = (entry['domain'] as String? ?? 'Unknown');
    final isHealthcare = domain.toLowerCase() == 'healthcare';
    final dotColor =
        isHealthcare ? AppColors.healthcarePrimary : AppColors.financePrimary;

    final summary = entry['plain_summary'] as String? ??
        entry['summary'] as String? ??
        'No summary available.';
    final timestamp = entry['date'] as String? ??
        entry['timestamp'] as String? ??
        entry['created_at'] as String? ?? '';
    final sentiment = entry['sentiment'] as String? ?? '';
    final fields = entry['domain_fields'] as Map? ??
        entry['structured_extraction']?['domain_fields'] as Map? ??
        {};

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Entry card
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: dotColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            domain,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: dotColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (sentiment.isNotEmpty)
                          Text(
                            sentiment.toLowerCase() == 'positive'
                                ? '🟢'
                                : sentiment.toLowerCase() == 'negative'
                                    ? '🔴'
                                    : '🟡',
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          timestamp.length > 10
                              ? timestamp.substring(0, 10)
                              : timestamp,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                    if (_expanded && fields.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: fields.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: '${e.key}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${e.value}',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_expanded) ...[
                          GestureDetector(
                            onTap: () => _showEditSheet(context, entry),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.healthcareSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.healthcarePrimary
                                        .withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 12,
                                      color: AppColors.healthcarePrimary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Correct',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.healthcarePrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> entry) {
    final dbId = entry['db_id']?.toString() ?? '';
    if (dbId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit: missing record ID.')),
      );
      return;
    }

    final transcriptController = TextEditingController(
      text: entry['transcript'] as String? ?? '',
    );
    final fields = Map<String, dynamic>.from(
      entry['domain_fields'] as Map? ?? {},
    );
    final extractionController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(fields),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Correct Record',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: $dbId',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              const Text(
                'TRANSCRIPT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: transcriptController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'STRUCTURED EXTRACTION (JSON)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: extractionController,
                maxLines: 5,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (ctx, setSheetState) {
                  bool saving = false;
                  return ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            Map<String, dynamic> parsedExtraction;
                            try {
                              parsedExtraction = Map<String, dynamic>.from(
                                jsonDecode(extractionController.text),
                              );
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid JSON in extraction field.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            final success = await ref
                                .read(timelineNotifierProvider.notifier)
                                .updateRecord(
                                  dbId,
                                  correctedTranscript: transcriptController.text.trim(),
                                  correctedExtraction: parsedExtraction,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Record updated successfully.'
                                      : 'Update failed. Please try again.'),
                                  backgroundColor:
                                      success ? AppColors.success : AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.healthcarePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Correction',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
