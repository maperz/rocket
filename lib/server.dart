import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get_ip/get_ip.dart';
import 'package:socket_io/socket_io.dart';
import 'package:flutter/services.dart' show rootBundle;

class RocketServer {
  static const int ServerPort = 4040;
  static const int WSPort = 4000;

  Server _io;
  HttpServer _server;

  List<File> _allFiles = List<File>();

  Future<String> start() async {
    if (_server != null) {
      return await getAddress();
    }
    _setupSocketIo();
    _server = await HttpServer.bind(
      "0.0.0.0",
      ServerPort,
    );

    _allFiles = List<File>();
    _run();
    return await getAddress();
  }

  void _run() async {
    await for (HttpRequest request in _server) {
      HttpResponse response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.contentType =
          new ContentType("text", "html", charset: "utf-8");
      response.write(await _getServerContent(request));

      await response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _io?.off('connection', _onConnected);
    _io?.close();
    _server = null;
    _io = null;
  }

  bool isRunning() {
    return _server != null && _io != null;
  }

  void _setupSocketIo() {
    _io = new Server();
    _io.on('connection', _onConnected);
    _io.listen(WSPort);
  }

  void _onConnected(client) async {
    print('Client connected');

    for (var file in _allFiles) {
      String name = file.path.split("/").last;
      var encoded = await _encodeFile(file);
      _io.emit("file", {"name": name, "data": encoded});
    }
  }

  void sendData(Object data) {
    _io.emit("data", data);
  }

  void sendFiles(List<File> files) async {
    _allFiles.addAll(files);
    for (var file in files) {
      await _sendFile(file);
    }
  }

  Future<String> _encodeFile(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  void _sendFile(File file) async {
    String name = file.path.split("/").last;
    var encoded = await _encodeFile(file);
    _io.emit("file", {"name": name, "data": encoded});
  }

  Future<String> getAddress() async {
    var ip = await GetIp.ipAddress;
    return ip + ":" + ServerPort.toString();
  }

  Future<String> getWSAddress() async {
    var ip = await GetIp.ipAddress;
    return ip + ":" + WSPort.toString();
  }

  Future<Object> _getServerContent(HttpRequest request) async {
    var site = await rootBundle.loadString('client/client.html');
    return site.replaceAll("###WSADDRESS###", await getWSAddress());
  }
}
