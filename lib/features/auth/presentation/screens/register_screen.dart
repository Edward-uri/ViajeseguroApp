import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/widgets.dart';
import '../provider/register_viewmodel.dart';
import 'register_email_step.dart';
import 'register_form_additional_step.dart';
import 'register_form_personal_step.dart';
import 'register_otp_step.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registerViewModelProvider.notifier).resetToEmail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    final vm = ref.read(registerViewModelProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: state.step == RegisterStep.email
            ? IconButton(
                icon: Icon(Icons.close, color: scheme.onSurface),
                onPressed: () {
                  vm.resetToEmail();
                  Navigator.of(context).pop();
                },
              )
            : IconButton(
                icon: Icon(Icons.arrow_back, color: scheme.onSurface),
                onPressed: () {
                  switch (state.step) {
                    case RegisterStep.otp:
                      vm.goBackToEmail();
                      break;
                    case RegisterStep.formPersonal:
                      vm.goBackToOtp();
                      break;
                    case RegisterStep.formAdditional:
                      vm.goBackToPersonalForm();
                      break;
                    default:
                      break;
                  }
                },
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Center(
                    child: SvgPicture.asset(
                      'lib/shared/icons/Mototaxi Línea.svg',
                      width: 160,
                      height: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Jala',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnimatedStep(state, vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStep(
    RegisterViewModelState state,
    RegisterViewModel vm,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.1, 0.0),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _buildStep(state, vm),
    );
  }

  Widget _buildStep(
    RegisterViewModelState state,
    RegisterViewModel vm,
  ) {
    switch (state.step) {
      case RegisterStep.email:
        return EmailStep(key: const ValueKey('email'), vm: vm, state: state);
      case RegisterStep.otp:
        return OtpStep(key: const ValueKey('otp'), vm: vm, state: state, correo: vm.correo);
      case RegisterStep.formPersonal:
        return FormPersonalStep(key: const ValueKey('personal'), vm: vm, state: state);
      case RegisterStep.formAdditional:
        return FormAdditionalStep(key: const ValueKey('additional'), vm: vm, state: state);
    }
  }
}
