part of 'main_bloc.dart';

abstract class MainEvent extends Equatable {
  const MainEvent();
}

class StartServerEvent extends MainEvent {
  @override
  List<Object> get props => [];
}

class StopServerEvent extends MainEvent {
  @override
  List<Object> get props => [];
}

class AddFilesEvent extends MainEvent {
  final List<File> files;
  AddFilesEvent(this.files);

  @override
  List<Object> get props => [files];
}
