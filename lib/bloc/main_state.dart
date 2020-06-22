part of 'main_bloc.dart';

class MainState extends Equatable {
  final isRunning;
  final isLoading;
  final onLocalNetwork;
  final address;
  final List<File> files;

  const MainState(
      {this.isRunning = false,
      this.address,
      this.files,
      this.isLoading = false,
      this.onLocalNetwork = true});

  @override
  List<Object> get props =>
      [address, files, isLoading, isRunning, onLocalNetwork];

  factory MainState.loading() {
    return MainState(isLoading: true);
  }

  factory MainState.stopped() {
    return MainState(isRunning: false);
  }

  factory MainState.running(String address) {
    return MainState(isRunning: true, address: address, files: []);
  }

  MainState addFiles(List<File> newFiles) {
    var copiedFiles = List<File>.from(files);
    copiedFiles.addAll(newFiles);
    return copyWith(files: copiedFiles);
  }

  MainState connectivityChanged({@required onLocalNetwork}) {
    return copyWith(onLocalNetwork: onLocalNetwork);
  }

  MainState copyWith({isRunning, address, files, isLoading, onLocalNetwork}) {
    return MainState(
        address: address ?? this.address,
        isRunning: isRunning ?? this.isRunning,
        files: files ?? this.files,
        isLoading: isLoading ?? this.isLoading,
        onLocalNetwork: onLocalNetwork ?? this.onLocalNetwork);
  }
}
