import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rocket/bloc/main_bloc.dart';
import 'package:rocket/constants.dart';
import 'package:rocket/server.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rocket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF18C371),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider(
          create: (BuildContext context) => MainBloc(RocketServer()),
          child: Material(child: MyHomePage(title: 'Rocket'))),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  RocketServer server;
  AnimationController _showSettingsAnimationController;

  AnimationController _serverRunningAnimationController;
  Animation<double> _animation;

  bool _openingSettings = false;
  bool _starting = false;

  @override
  void initState() {
    _showSettingsAnimationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 200));

    _serverRunningAnimationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 200));

    _animation =
        Tween(begin: 0.0, end: 1.0).animate(_serverRunningAnimationController)
          ..addListener(() {
            setState(() {});
          });

    super.initState();
  }

  _toggleSettings() {
    _openingSettings = !_openingSettings;
    _openingSettings
        ? _showSettingsAnimationController.forward()
        : _showSettingsAnimationController.reverse();
  }

  _startServer(context) {
    BlocProvider.of<MainBloc>(context).add(StartServerEvent());
  }

  _stopServer(context) {
    BlocProvider.of<MainBloc>(context).add(StopServerEvent());
  }

  @override
  Widget build(BuildContext context) {
    var radiusTween = Tween(begin: 0.0, end: 37.0).animate(_animation);
    var borderRadius = Radius.circular(radiusTween.value);
    var inverseAnimation = 1.0 - _animation.value;

    var settingsPanel = Tween(begin: 0.0, end: -80.0).animate(_animation);

    var containerHeight =
        Tween(begin: MediaQuery.of(context).size.height, end: 300.0)
            .animate(_animation);

    return BlocConsumer<MainBloc, MainState>(
      listener: (context, state) {
        if (state is ServerRunning) {
          setState(() {
            _serverRunningAnimationController.forward();
          });
        }

        if (state is NotStarted) {
          setState(() {
            _showSettingsAnimationController.reverse();
            _serverRunningAnimationController.reverse();
          });
        }
      },
      builder: (context, state) =>
          Stack(alignment: Alignment.topCenter, children: [
        if (state is ServerRunning)
          Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: (state.files.length == 0)
                  ? Padding(
                      padding: EdgeInsets.only(top: 340),
                      child: NoFilesPlaceholder(),
                    )
                  : FileGrid(state.files)),
        Positioned(
          bottom: 40,
          child: _ScaledWithAlpha(
              child: FloatingActionButton(
                backgroundColor: Theme.of(context).primaryColor,
                onPressed: () => _showFilePicker(context),
                child: Icon(Icons.add_a_photo),
              ),
              value: _animation.value),
        ),
        Transform.translate(
          offset: Offset(0, 0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: containerHeight.value,
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(75),
                      offset: Offset(0, 4),
                      blurRadius: 20)
                ],
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                    bottomLeft: borderRadius, bottomRight: borderRadius)),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RocketLogo(size: inverseAnimation),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: _ScaledWithAlpha(
                          value: _animation.value,
                          child: AddressInfo(
                              state is ServerRunning ? state.address : ""),
                        ),
                      ),
                      _ScaledWithAlpha(
                          value: inverseAnimation,
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                height: inverseAnimation * 20,
                              ),
                              Text("File sharing is rocket science",
                                  style:
                                      kHeaderTextStyle.copyWith(fontSize: 20)),
                              SizedBox(
                                height: inverseAnimation * 60,
                              ),
                              StartButton(() => _startServer(context))
                            ],
                          ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        Positioned(
            top: 270,
            child: _ScaledWithAlpha(
                value: _animation.value * 2 - 1.0,
                child: StopButton(() => _stopServer(context)))),
        Positioned(
          bottom: settingsPanel.value,
          left: 0,
          right: 0,
          child: Align(
              alignment: Alignment.bottomCenter,
              child: SettingsPanel(
                  _showSettingsAnimationController, _toggleSettings)),
        )
      ]),
    );
  }

  _ScaledWithAlpha({value, child}) {
    return Opacity(
        opacity: max(value, 0),
        child: Transform.scale(scale: value, child: child));
  }

  _showFilePicker(context) async {
    var files = await FilePicker.getMultiFile(type: FileType.image);
    BlocProvider.of<MainBloc>(context).add(AddFilesEvent(files));
  }
}

class FileGrid extends StatelessWidget {
  final List<File> _files;

  FileGrid(this._files);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        padding: EdgeInsets.only(top: 320),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20),
        itemBuilder: (context, index) => FileItem(() => {}, _files[index]),
        itemCount: _files.length,
      ),
    );
  }
}

class FileItem extends StatelessWidget {
  final Function onRemoveClicked;
  final File _file;

  FileItem(this.onRemoveClicked, this._file);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(_file, fit: BoxFit.cover));
  }
}

class NoFilesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Image.asset(
            "assets/empty.png",
            width: 270,
            height: 225,
          ),
        ),
        Text(
          "No files shared",
          style: kHeaderTextStyle.copyWith(color: Colors.black, fontSize: 32),
        ),
        SizedBox(
          height: 20,
        ),
        Text("Add new files to be shared.",
            style: TextStyle(fontSize: 16, color: Color(0xFF7D7D7D)))
      ],
    );
  }
}

class SettingsPanel extends StatefulWidget {
  AnimationController controller;
  Function toggleVisibility;

  SettingsPanel(this.controller, this.toggleVisibility);
  @override
  _SettingsPanelState createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  Animation<double> _heightAnimation;

  final double _minValue = 80;
  final double _maxValue = 300;

  @override
  void initState() {
    this._heightAnimation = Tween<double>(begin: _minValue, end: _maxValue)
        .animate(this.widget.controller)
          ..addListener(() => setState(() => {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      height: _heightAnimation.value,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            offset: Offset(0, -4),
            blurRadius: 20,
            color: Colors.black.withAlpha(70))
      ], color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: GestureDetector(
        onTap: this.widget.toggleVisibility,
        child: Container(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _heightAnimation.value < (_maxValue - _minValue) / 2
                      ? "Show Settings"
                      : "Hide Settings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                Transform.rotate(
                    angle: -pi *
                        (_heightAnimation.value - _minValue) /
                        (_maxValue - _minValue),
                    child: Icon(Icons.arrow_upward))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StartButton extends StatelessWidget {
  final Function onClick;

  StartButton(this.onClick);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        elevation: 10,
        onPressed: onClick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 86, vertical: 18),
          child: Text(
            "Start",
            style: kHeaderTextStyle.copyWith(color: Colors.black, fontSize: 36),
          ),
        ),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)));
  }
}

class StopButton extends StatelessWidget {
  final Function onClick;

  StopButton(this.onClick);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        elevation: 10,
        onPressed: onClick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Text(
            "Stop sharing",
            style: kHeaderTextStyle.copyWith(color: Colors.white, fontSize: 18),
          ),
        ),
        color: Color(0xFFF03434),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
  }
}

class RocketLogo extends StatelessWidget {
  double size;

  RocketLogo({this.size}) {
    this.size ??= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text("Rocket",
            style: kHeaderTextStyle.copyWith(fontSize: 50 + (72 - 50) * size)),
        SizedBox(
          height: 8,
        ),
        Container(
          width: 230,
          height: 3,
          color: Colors.white,
        ),
      ],
    );
  }
}

class AddressInfo extends StatelessWidget {
  final String _address;

  AddressInfo(this._address);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Container(
      width: size.width - 16 * 2,
      height: 104,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(110),
                offset: Offset(0, 8),
                blurRadius: 20)
          ]),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _grayCircle(),
                SizedBox(
                  width: 4,
                ),
                _grayCircle(),
                SizedBox(
                  width: 4,
                ),
                _grayCircle(),
              ],
            ),
            SizedBox(
              height: 14,
            ),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Text.rich(TextSpan(
                children: <TextSpan>[
                  TextSpan(
                      text: 'http:// ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA5A5A5))),
                  TextSpan(
                      text: _address,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              )),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Color(0xFFF0EEEE)),
            ),
          ],
        ),
      ),
    );
  }

  _grayCircle() {
    return Container(
        width: 20,
        height: 20,
        decoration: new BoxDecoration(
          color: Color(0xFFF0EEEE),
          shape: BoxShape.circle,
        ));
  }
}
