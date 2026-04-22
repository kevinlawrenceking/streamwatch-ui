part of 'reported_slots_bloc.dart';

abstract class ReportedSlotsState extends Equatable {
  const ReportedSlotsState();

  @override
  List<Object?> get props => [];
}

class ReportedSlotsInitial extends ReportedSlotsState {
  const ReportedSlotsInitial();
}

class ReportedSlotsLoading extends ReportedSlotsState {
  const ReportedSlotsLoading();
}

class ReportedSlotsLoaded extends ReportedSlotsState {
  final String reportKey;
  final List<PodcastScheduleSlot> slots;
  final bool hasMore;
  final int currentPage;

  const ReportedSlotsLoaded({
    required this.reportKey,
    required this.slots,
    required this.hasMore,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [reportKey, slots, hasMore, currentPage];
}

class ReportedSlotsError extends ReportedSlotsState {
  final String message;
  const ReportedSlotsError(this.message);

  @override
  List<Object?> get props => [message];
}
