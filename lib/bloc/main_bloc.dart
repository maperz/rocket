import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../server.dart';

part 'main_event.dart';
part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  RocketServer server;
  MainBloc(this.server);

  @override
  MainState get initialState => NotStarted();

  @override
  Stream<MainState> mapEventToState(
    MainEvent event,
  ) async* {
    MainState current = state;

    if (event is StartServerEvent && !server.isRunning()) {
      yield ServerLoading();
      String address = await server.start();
      yield ServerRunning(address, []);
    }
    if (event is StopServerEvent && server.isRunning()) {
      await server.stop();
      yield NotStarted();
    }

    if (event is AddFilesEvent &&
        server.isRunning() &&
        current is ServerRunning) {
      server.sendFiles(event.files);
      yield current.AddFiles(event.files);
    }
  }
}
