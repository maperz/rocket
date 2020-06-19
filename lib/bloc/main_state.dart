part of 'main_bloc.dart';

abstract class MainState extends Equatable {
  const MainState();
}

class NotStarted extends MainState {
  @override
  List<Object> get props => [];
}

class ServerLoading extends MainState {
  @override
  List<Object> get props => [];
}

class ServerRunning extends MainState {
  final String address;
  final List<File> files;

  ServerRunning(this.address, this.files);

  @override
  List<Object> get props => [address, files];

  ServerRunning AddFiles(List<File> newFiles) {
    var copiedFiles = List<File>.from(files);
    copiedFiles.addAll(newFiles);
    return ServerRunning(
      this.address,
      copiedFiles,
    );
  }
}
