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

class ConnectivityChangedEvent extends MainEvent {
  final bool onLocalNetwork;
  ConnectivityChangedEvent(this.onLocalNetwork);

  @override
  List<Object> get props => [onLocalNetwork];
}

class AddFilesEvent extends MainEvent {
  final List<File> files;
  AddFilesEvent(this.files);

  @override
  List<Object> get props => [files];
}
