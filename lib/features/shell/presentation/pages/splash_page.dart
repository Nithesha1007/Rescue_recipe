import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/voice_orb.dart';
import '../../../recipes/domain/entities/diet_tag.dart';
import '../../../settings/domain/entities/user_preferences.dart';
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
    final prefs = context.read<SettingsCubit>().state.preferences;
    final isReducedMotion = prefs.reduceMotion;
    final delay = isReducedMotion ? const Duration(milliseconds: 150) : const Duration(milliseconds: 1200);

    await Future.delayed(delay);
    if (!mounted) return;

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

/// 4-step guided onboarding flow with skip and live preference configuration.
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

  late VoiceInputLanguage _voiceLang;
  late GuideLanguage _guideLang;
  late DietTag _diet;
  int _householdSize = 2;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<SettingsCubit>().state.preferences;
    _voiceLang = prefs.voiceInputLanguage;
    _guideLang = prefs.guideLanguage;
    _diet = prefs.diet;
    _householdSize = prefs.householdSize;
    _nameController = TextEditingController(text: prefs.displayName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    final cubit = context.read<SettingsCubit>();
    final current = cubit.state.preferences;
    final name = _nameController.text.trim();

    cubit.updatePreferences(current.copyWith(
      hasCompletedOnboarding: true,
      voiceInputLanguage: _voiceLang,
      guideLanguage: _guideLang,
      diet: _diet,
      householdSize: _householdSize,
      displayName: name.isNotEmpty ? name : 'Food Rescuer',
    ));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
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
                  _buildLanguagePage(),
                  _buildProfilePage(),
                  _buildHowItWorksPage(),
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
                      4,
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
                  if (_currentPage < 3)
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

  Widget _buildLanguagePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌐', style: AppTypography.displayEmoji),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Choose Your Languages',
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Speak naturally in Tamil, Hindi, or English. RescueRecipe understands all three.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Input Mode', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonHideUnderline(
                  child: DropdownButton<VoiceInputLanguage>(
                    isExpanded: true,
                    value: _voiceLang,
                    items: const [
                      DropdownMenuItem(
                        value: VoiceInputLanguage.auto,
                        child: Text('Auto (AI) - Tamil, Hindi, English, Mixed'),
                      ),
                      DropdownMenuItem(
                        value: VoiceInputLanguage.english,
                        child: Text('Live - English (India)'),
                      ),
                      DropdownMenuItem(
                        value: VoiceInputLanguage.tamil,
                        child: Text('Live - Tamil (தமிழ்)'),
                      ),
                      DropdownMenuItem(
                        value: VoiceInputLanguage.hindi,
                        child: Text('Live - Hindi (हिंदी)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _voiceLang = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cooking Guide Language', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonHideUnderline(
                  child: DropdownButton<GuideLanguage>(
                    isExpanded: true,
                    value: _guideLang,
                    items: const [
                      DropdownMenuItem(value: GuideLanguage.english, child: Text('English')),
                      DropdownMenuItem(value: GuideLanguage.tamil, child: Text('Tamil (தமிழ்)')),
                      DropdownMenuItem(value: GuideLanguage.hindi, child: Text('Hindi (हिंदी)')),
                      DropdownMenuItem(value: GuideLanguage.tanglish, child: Text('Tanglish (Tamil in English)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _guideLang = val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🧑‍🍳', style: AppTypography.displayEmoji),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your Kitchen Profile',
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Customize your dietary needs and household size for perfectly portioned recipes.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'What should we call you?',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dietary Restrictions', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: DietTag.values.map((tag) {
                    final isSel = _diet == tag;
                    return ChoiceChip(
                      label: Text(tag.displayName),
                      selected: isSel,
                      selectedColor: AppColors.orange,
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.white : null,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _diet = tag);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Household Size', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: _householdSize > 1 ? () => setState(() => _householdSize--) : null,
                    ),
                    Text('$_householdSize', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _householdSize < 10 ? () => setState(() => _householdSize++) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌱', style: AppTypography.displayEmoji),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Rescue Food in 3 Steps',
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildStepRow('1', 'Speak Ingredients', 'Say items in plain words with natural expiry phrases like "use in 3 days".'),
          const SizedBox(height: AppSpacing.md),
          _buildStepRow('2', 'Rescue-First Ranking', '0ms local pure Dart algorithm ranks recipes that save your most critical food first.'),
          const SizedBox(height: AppSpacing.md),
          _buildStepRow('3', 'Cook Hands-Free', 'Step-by-step guidance recites exact quantities and responds to voice commands.'),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.orange,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(description, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
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
              'Ready to Cook!',
              textAlign: TextAlign.center,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Granting permissions enables voice recording and timely expiry reminders. You can adjust these anytime in settings.',
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
