import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/voice_orb.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import 'app_shell.dart';

/// Animated Splash screen that seamlessly transitions to Onboarding or MainShell.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;

    final prefs = context.read<SettingsCubit>().state.preferences;
    if (prefs.hasCompletedOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const VoiceOrb(
              active: true,
              level: 0.8,
              semanticLabel: 'RescueRecipe Orb',
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'RescueRecipe',
              style: context.text.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Speak. Rescue. Cook.',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.mist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3-page swipeable onboarding explaining permissions and food rescue.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _micAllowed = false;
  bool _notifsAllowed = false;

  void _finishOnboarding() {
    final cubit = context.read<SettingsCubit>();
    final current = cubit.state.preferences;
    cubit.updatePreferences(current.copyWith(hasCompletedOnboarding: true));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage(
                    emoji: '🎙️',
                    title: 'Speak Your Ingredients',
                    subtitle: 'Just tap the mic and say what is in your fridge or pantry. Natural language handles quantities, units, and expiry dates.',
                  ),
                  _buildPage(
                    emoji: '⏳',
                    title: 'Rescue What Expires First',
                    subtitle: 'Rescue-First ranking prioritizes dishes using items about to expire, helping you reduce waste and save money.',
                  ),
                  _buildPermissionsPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.orange : context.colors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage < 2)
                    AppButton(
                      label: 'Next',
                      variant: AppButtonVariant.filled,
                      onPressed: () {
                        _pageController.nextPage(
                          duration: AppDurations.normal,
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  else
                    AppButton(
                      label: 'Get Started',
                      variant: AppButtonVariant.filled,
                      onPressed: _finishOnboarding,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: AppTypography.displayEmoji),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍳', style: AppTypography.displayEmoji),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Cook Hands-Free',
              textAlign: TextAlign.center,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hands covered in flour? Use voice commands like "next", "repeat", or "start timer". Granting permissions is optional.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.mic, color: AppColors.orange),
                title: const Text('Microphone'),
                subtitle: const Text('For speaking ingredients & voice cooking'),
                trailing: _micAllowed
                    ? const Icon(Icons.check_circle, color: AppColors.low)
                    : OutlinedButton(
                        onPressed: () async {
                          final status = await Permission.microphone.request();
                          if (mounted && status.isGranted) {
                            setState(() => _micAllowed = true);
                          }
                        },
                        child: const Text('Allow'),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined, color: AppColors.orange),
                title: const Text('Expiry Alerts'),
                subtitle: const Text('Reminders before food goes bad'),
                trailing: _notifsAllowed
                    ? const Icon(Icons.check_circle, color: AppColors.low)
                    : OutlinedButton(
                        onPressed: () async {
                          final status = await Permission.notification.request();
                          if (mounted && status.isGranted) {
                            setState(() => _notifsAllowed = true);
                          }
                        },
                        child: const Text('Allow'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
