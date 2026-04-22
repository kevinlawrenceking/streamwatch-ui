part of 'reported_slots_bloc.dart';

abstract class ReportedSlotsEvent extends Equatable {
  const ReportedSlotsEvent();

  @override
  List<Object?> get props => [];
}

class FetchReportedSlotsEvent extends ReportedSlotsEvent {
  final String reportKey;
  final int page;
  final int pageSize;

  const FetchReportedSlotsEvent({
    required this.reportKey,
    this.page = 1,
    this.pageSize = 50,
  });

  @override
  List<Object?> get props => [reportKey, page, pageSize];
}
