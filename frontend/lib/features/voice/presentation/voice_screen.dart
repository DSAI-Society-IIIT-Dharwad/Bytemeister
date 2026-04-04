import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../review/presentation/review_screen.dart';
import '../domain/voice_state.dart';
import 'voice_notifier.dart';
import 'widgets/waveform_visualizer.dart';

class VoiceScreen extends ConsumerWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceNotifierProvider);
    final notifier = ref.read(voiceNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voice Session'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.locale,
                icon: const Icon(Icons.language, color: AppColors.healthcarePrimary, size: 20),
                style: textTheme.bodyMedium?.copyWith(color: AppColors.healthcarePrimary),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(value: 'en-US', child: Text('English')),
                  DropdownMenuItem(value: 'hi-IN', child: Text('Hindi')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    notifier.changeLocale(newValue);
                  }
                },
              ),
            ),
          ),
          if (state.transcript != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReviewScreen()),
                  );
                },
                icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Review'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.healthcarePrimary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (state.status == VoiceStatus.recording)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOutSine,
                      builder: (context, value, child) => Container(
                        width: 200 * value,
                        height: 200 * value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.healthcarePrimary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  Container(
                    width: 280,
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: state.status == VoiceStatus.recording
                        ? CustomPaint(
                            painter: WaveformVisualizer(
                              data: state.waveformData,
                              color: AppColors.healthcarePrimary,
                            ),
                          )
                        : state.status == VoiceStatus.initializing
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 3),
                                  const SizedBox(height: 16),
                                  Text('Initializing ML Kit...', style: textTheme.bodyMedium),
                                ],
                              )
                        : state.status == VoiceStatus.downloading
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(strokeWidth: 3),
                                  const SizedBox(height: 16),
                                  Text('Downloading Speech Model...', style: textTheme.bodyMedium),
                                ],
                              )
                        : state.status == VoiceStatus.processing
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                      strokeWidth: 3),
                                  const SizedBox(height: 16),
                                  Text('Uploading & Analysing...',
                                      style: textTheme.bodyMedium),
                                ],
                              )
                            : state.status == VoiceStatus.error
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error, size: 48),
                                      const SizedBox(height: 16),
                                      Text(
                                          state.errorMessage ??
                                              'An error occurred',
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodyMedium?.copyWith(
                                              color: AppColors.error)),
                                      TextButton(
                                        onPressed: () => ref
                                            .read(
                                                voiceNotifierProvider.notifier)
                                            .startRecording(),
                                        child: const Text('Try Again'),
                                      )
                                    ],
                                  )
                                : Text(
                                    'Tap to start capturing multilingual dialogue',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.healthcarePrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'LIVE TRANSCRIPT',
                        style: textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (state.audioPath != null && state.status == VoiceStatus.idle)
                        TextButton.icon(
                          onPressed: () => notifier.togglePlayback(),
                          icon: Icon(
                            state.isPlaying ? Icons.stop_circle : Icons.play_circle,
                            color: AppColors.healthcarePrimary,
                          ),
                          label: Text(
                            state.isPlaying ? 'Stop' : 'Play Audio',
                            style: const TextStyle(color: AppColors.healthcarePrimary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        state.transcript ?? 'Awaiting audio input...',
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.6,
                          color: state.transcript == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () {
            if (state.status == VoiceStatus.idle ||
                state.status == VoiceStatus.error) {
              notifier.startRecording();
            } else if (state.status == VoiceStatus.recording) {
              notifier.stopRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: (state.status == VoiceStatus.initializing || state.status == VoiceStatus.downloading) ? 24 : 20,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: state.status == VoiceStatus.recording
                  ? AppColors.error
                  : (state.status == VoiceStatus.initializing || state.status == VoiceStatus.downloading)
                      ? AppColors.textTertiary
                      : AppColors.healthcarePrimary,
              boxShadow: [
                BoxShadow(
                  color: (state.status == VoiceStatus.recording
                          ? AppColors.error
                          : (state.status == VoiceStatus.initializing || state.status == VoiceStatus.downloading)
                              ? AppColors.textTertiary
                              : AppColors.healthcarePrimary)
                      .withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.status == VoiceStatus.initializing || state.status == VoiceStatus.downloading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    state.status == VoiceStatus.recording
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                if (state.status == VoiceStatus.initializing || state.status == VoiceStatus.downloading)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      state.status == VoiceStatus.initializing ? 'Initializing...' : 'Downloading...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
