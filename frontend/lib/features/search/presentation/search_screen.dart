import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _activeFilter = 'All';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchNotifierProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

    final filtered = _activeFilter == 'All'
        ? state.results
        : state.results
            .where((r) =>
                (r['domain'] as String?)?.toLowerCase() ==
                _activeFilter.toLowerCase())
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Semantic Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by meaning — "chest pain", "loan repayment"…',
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchNotifierProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => ref.read(searchNotifierProvider.notifier).search(v),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Domain filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: ['All', 'Healthcare', 'Finance'].map((filter) {
                final selected = _activeFilter == filter;
                final chipColor = filter == 'Healthcare'
                    ? AppColors.healthcarePrimary
                    : filter == 'Finance'
                        ? AppColors.financePrimary
                        : AppColors.textSecondary;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) => setState(() => _activeFilter = filter),
                    selectedColor: chipColor.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? chipColor : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? chipColor : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child: _buildBody(state, filtered, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState state, List<Map<String, dynamic>> results,
      TextTheme textTheme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.query.isEmpty) {
      return _EmptyPrompt(
        icon: Icons.manage_search_rounded,
        title: 'Search by Meaning',
        subtitle:
            'Try "cardiac issues" to find records about heart conditions,\nor "loan repayment" for financial interactions.',
        color: AppColors.healthcarePrimary,
      );
    }

    if (results.isEmpty) {
      return _EmptyPrompt(
        icon: Icons.search_off_rounded,
        title: 'No Results Found',
        subtitle: 'No records matched "${state.query}".\nTry a different term.',
        color: AppColors.textTertiary,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = results[index];
        return _SearchResultCard(record: record);
      },
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyPrompt({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _SearchResultCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final domain = (record['domain'] as String? ?? 'Unknown');
    final isHealthcare = domain.toLowerCase() == 'healthcare';
    final primaryColor =
        isHealthcare ? AppColors.healthcarePrimary : AppColors.financePrimary;
    final surfaceColor =
        isHealthcare ? AppColors.healthcareSurface : AppColors.financeSurface;

    final summary = record['plain_summary'] as String? ??
        record['summary'] as String? ??
        'No summary available.';
    final userId = record['user_id'] as String? ?? '';
    final timestamp = record['timestamp'] as String? ??
        record['created_at'] as String? ?? '';
    final sentiment = record['sentiment'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHealthcare
                          ? Icons.medical_services_outlined
                          : Icons.account_balance_wallet_outlined,
                      size: 12,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      domain,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (sentiment.isNotEmpty) _SentimentBadge(sentiment: sentiment),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (userId.isNotEmpty || timestamp.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (userId.isNotEmpty) ...[
                  const Icon(Icons.person_outline,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    userId,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
                const Spacer(),
                if (timestamp.isNotEmpty)
                  Text(
                    timestamp.length > 10
                        ? timestamp.substring(0, 10)
                        : timestamp,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentBadge extends StatelessWidget {
  final String sentiment;

  const _SentimentBadge({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    final lower = sentiment.toLowerCase();
    final color = lower == 'positive'
        ? AppColors.success
        : lower == 'negative'
            ? AppColors.error
            : AppColors.warning;
    final emoji =
        lower == 'positive' ? '🟢' : lower == 'negative' ? '🔴' : '🟡';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $sentiment',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
