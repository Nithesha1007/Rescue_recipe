import 'package:equatable/equatable.dart';
import '../../domain/entities/cooking_session.dart';
import '../../domain/entities/inventory_deduction.dart';
import '../../domain/services/voice_session_controller.dart';

enum CookingFlowStatus {
  initial,
  loading,
  running,
  paused,
  confirmingFinish,
  finished,
  error,
}

class CookingState extends Equatable {
  final CookingFlowStatus flowStatus;
  final CookingSession? session;
  final AudioSessionState audioState;
  final String? spokenFeedback;
  final List<InventoryDeductionProposal> deductionProposals;
  final int rescuedCount;
  final int totalDeducted;
  final String? errorMessage;
  final bool isSafetyPromptSpoken;

  const CookingState({
    this.flowStatus = CookingFlowStatus.initial,
    this.session,
    this.audioState = AudioSessionState.idle,
    this.spokenFeedback,
    this.deductionProposals = const [],
    this.rescuedCount = 0,
    this.totalDeducted = 0,
    this.errorMessage,
    this.isSafetyPromptSpoken = false,
  });

  bool get isPaused => flowStatus == CookingFlowStatus.paused;

  CookingState copyWith({
    CookingFlowStatus? flowStatus,
    CookingSession? session,
    AudioSessionState? audioState,
    String? spokenFeedback,
    List<InventoryDeductionProposal>? deductionProposals,
    int? rescuedCount,
    int? totalDeducted,
    String? errorMessage,
    bool? isSafetyPromptSpoken,
  }) {
    return CookingState(
      flowStatus: flowStatus ?? this.flowStatus,
      session: session ?? this.session,
      audioState: audioState ?? this.audioState,
      spokenFeedback: spokenFeedback ?? this.spokenFeedback,
      deductionProposals: deductionProposals ?? this.deductionProposals,
      rescuedCount: rescuedCount ?? this.rescuedCount,
      totalDeducted: totalDeducted ?? this.totalDeducted,
      errorMessage: errorMessage,
      isSafetyPromptSpoken: isSafetyPromptSpoken ?? this.isSafetyPromptSpoken,
    );
  }

  @override
  List<Object?> get props => [
        flowStatus,
        session,
        audioState,
        spokenFeedback,
        deductionProposals,
        rescuedCount,
        totalDeducted,
        errorMessage,
        isSafetyPromptSpoken,
      ];
}
