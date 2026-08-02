import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../../core/routing/page_transitions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_mark.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/staggered_fade_in.dart';
import '../../widgets/wordmark.dart';
import '../login/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.showsCloseButton = false});

  /// True when opened from Home's info icon (as a revisit), rather than
  /// as the app's entry flow — shows a close affordance instead of
  /// replacing the navigation stack on continue.
  final bool showsCloseButton;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _markController;
  late final Animation<double> _markScale;

  @override
  void initState() {
    super.initState();
    _markController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _markScale = CurvedAnimation(
      parent: _markController,
      curve: Curves.easeOutBack,
    );
    _markController.forward();
  }

  @override
  void dispose() {
    _markController.dispose();
    super.dispose();
  }

  void _continue() {
    if (widget.showsCloseButton) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      fadeRoute(
        const LoginScreen(),
        settings: const RouteSettings(name: AppRoutes.login),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: widget.showsCloseButton
          ? AppBar(
              backgroundColor: c.background,
              leading: Semantics(
                label: 'Close',
                button: true,
                child: IconButton(
                  icon: Icon(Icons.close, color: c.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
          ),
          child: Column(
            children: [
              const Spacer(flex: 3),
              ScaleTransition(
                scale: _markScale,
                child: const AppMark(size: 96),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wordmark(fontSize: 30, color: c.textPrimary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Minimal tasks. Nothing else.',
                style: AppTextStyles.body.copyWith(color: c.textSecondary),
              ),
              const Spacer(flex: 2),
              StaggeredFadeIn(
                index: 0,
                child: const _FeatureRow(
                  icon: Icons.checklist_outlined,
                  title: 'Capture everything',
                  subtitle: 'Add, edit and organise your tasks in seconds.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StaggeredFadeIn(
                index: 1,
                child: const _FeatureRow(
                  icon: Icons.flag_outlined,
                  title: 'Stay on priority',
                  subtitle: 'Sort by priority and due date, automatically.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StaggeredFadeIn(
                index: 2,
                child: const _FeatureRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Built for both themes',
                  subtitle: 'A clean black-and-white interface, day or night.',
                ),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: widget.showsCloseButton ? 'Done' : 'Get Started',
                onPressed: _continue,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
          child: Icon(icon, size: 18, color: c.textPrimary),
        ),
        const SizedBox(width: AppSpacing.sm2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.taskTitle.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.meta.copyWith(
                  color: c.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
