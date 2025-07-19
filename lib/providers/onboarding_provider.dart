import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingStep {
  appTour,
  chat,
  mentalPeace,
  doctor,
  quickAccess,
  done,
}

class OnboardingState {
  final bool appTourDone;
  final bool chatDone;
  final bool mentalPeaceDone;
  final bool doctorDone;
  final bool quickAccessDone;
  final bool completed;
  final OnboardingStep currentStep;

  const OnboardingState({
    required this.appTourDone,
    required this.chatDone,
    required this.mentalPeaceDone,
    required this.doctorDone,
    required this.quickAccessDone,
    required this.completed,
    required this.currentStep,
  });

  OnboardingState copyWith({
    bool? appTourDone,
    bool? chatDone,
    bool? mentalPeaceDone,
    bool? doctorDone,
    bool? quickAccessDone,
    bool? completed,
    OnboardingStep? currentStep,
  }) {
    return OnboardingState(
      appTourDone: appTourDone ?? this.appTourDone,
      chatDone: chatDone ?? this.chatDone,
      mentalPeaceDone: mentalPeaceDone ?? this.mentalPeaceDone,
      doctorDone: doctorDone ?? this.doctorDone,
      quickAccessDone: quickAccessDone ?? this.quickAccessDone,
      completed: completed ?? this.completed,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState(
    appTourDone: false,
    chatDone: false,
    mentalPeaceDone: false,
    doctorDone: false,
    quickAccessDone: false,
    completed: false,
    currentStep: OnboardingStep.appTour,
  )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final appTourDone = prefs.getBool('onboarding_app_tour_done') ?? false;
    final chatDone = prefs.getBool('onboarding_chat_done') ?? false;
    final mentalPeaceDone = prefs.getBool('onboarding_mental_done') ?? false;
    final doctorDone = prefs.getBool('onboarding_doctor_done') ?? false;
    final quickAccessDone = prefs.getBool('onboarding_quickaccess_done') ?? false;
    final completed = prefs.getBool('onboardingCompleted') ?? false;
    final step = _calculateStep(appTourDone, chatDone, mentalPeaceDone, doctorDone, quickAccessDone, completed);
    state = state.copyWith(
      appTourDone: appTourDone,
      chatDone: chatDone,
      mentalPeaceDone: mentalPeaceDone,
      doctorDone: doctorDone,
      quickAccessDone: quickAccessDone,
      completed: completed,
      currentStep: step,
    );
  }

  OnboardingStep _calculateStep(bool appTour, bool chat, bool mental, bool doctor, bool quick, bool completed) {
    if (completed) return OnboardingStep.done;
    if (!appTour) return OnboardingStep.appTour;
    if (!chat) return OnboardingStep.chat;
    if (!mental) return OnboardingStep.mentalPeace;
    if (!doctor) return OnboardingStep.doctor;
    if (!quick) return OnboardingStep.quickAccess;
    return OnboardingStep.done;
  }

  Future<void> markStepDone(OnboardingStep step) async {
    final prefs = await SharedPreferences.getInstance();
    switch (step) {
      case OnboardingStep.appTour:
        await prefs.setBool('onboarding_app_tour_done', true);
        break;
      case OnboardingStep.chat:
        await prefs.setBool('onboarding_chat_done', true);
        break;
      case OnboardingStep.mentalPeace:
        await prefs.setBool('onboarding_mental_done', true);
        break;
      case OnboardingStep.doctor:
        await prefs.setBool('onboarding_doctor_done', true);
        break;
      case OnboardingStep.quickAccess:
        await prefs.setBool('onboarding_quickaccess_done', true);
        await prefs.setBool('onboardingCompleted', true);
        break;
      case OnboardingStep.done:
        break;
    }
    // Reload state after marking
    await _load();
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) => OnboardingNotifier()); 