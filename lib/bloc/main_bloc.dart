import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../server.dart';

part 'main_event.dart';
part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  RocketServer server;
  MainBloc(this.server);

  @override
  MainState get initialState => MainState.stopped();

  @override
  Stream<MainState> mapEventToState(
    MainEvent event,
  ) async* {
    if (event is StartServerEvent && !server.isRunning()) {
      yield MainState.loading();
      String address = await server.start();
      yield MainState.running(address);
    }

    if (event is StopServerEvent && server.isRunning()) {
      await server.stop();
      yield MainState.stopped();
    }

    if (event is ConnectivityChangedEvent) {
      yield state.connectivityChanged(onLocalNetwork: event.onLocalNetwork);
    }

    if (event is AddFilesEvent && server.isRunning() && state.isRunning) {
      server.sendFiles(event.files);
      yield state.addFiles(event.files);
    }
  }
}
