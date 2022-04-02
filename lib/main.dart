import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dashnes/bridge_generated.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _width = 256.0;
const _height = 240.0;
const _primaryColor = Color(0xFF940A24);
const _buttonColor = Color(0xFF17212D);
const _directionColor = Color(0xFF17212D);
const _nesColor = Color(0xFFCEBE8E);
const _seColor = Color(0xFF17212D);
const _paddingColor = Color(0xFF5C1623);
const _screenColor = Color(0xFF485055);

const base = 'rnes';
final path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
late final dylib = Platform.isIOS
    ? DynamicLibrary.process()
    : Platform.isMacOS
        ? DynamicLibrary.executable()
        : DynamicLibrary.open(path);
late final api = RnesImpl(dylib);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final parentRx = ReceivePort();

  Isolate.spawn(_launchNes, parentRx.sendPort);

  ValueNotifier<ui.Image?> image = ValueNotifier(null);
  ValueNotifier<int> fps = ValueNotifier(0);
  SendPort? childTx;

  parentRx.listen((e) {
    if (e is SendPort) {
      childTx = e;
    }

    if (e is RenderFrameEvent) {
      ui.decodeImageFromPixels(e.frame, 256, 240, ui.PixelFormat.rgba8888,
          (result) {
        image.value = result;
      });
    }

    if (e is FpsUpdateEvent) {
      fps.value = e.fps;
    }
  });

  runApp(MyApp(
    image: image,
    fps: fps,
    onRomSelected: (bytes) {
      childTx?.send(FileSelectedEvent(bytes));
    },
    onKeyPressed: (key) {
      childTx?.send(KeyPressedEvent(key));
    },
    onKeyReleased: (key) {
      childTx?.send(KeyReleasedEvent(key));
    },
  ));
}

bool _ready = false;

void _launchNes(SendPort parentTx) async {
  final childRx = ReceivePort();

  parentTx.send(childRx.sendPort);

  childRx.listen((message) async {
    if (message is FileSelectedEvent) {
      await api.loadRom(bytes: message.bytes);
      await api.reset();
      _ready = true;
    }

    if (!_ready) return;

    if (message is KeyPressedEvent) {
      await api.player1Keydown(key: message.key);
    }

    if (message is KeyReleasedEvent) {
      await api.player1Keyup(key: message.key);
    }
  });

  var prevDateTime = DateTime.now();
  var frameCount = 0;
  var fpsTotal = 0.0;
  var sleep = const Duration(milliseconds: 16);

  while (true) {
    if (_ready) {
      final pixels = await api.render();

      parentTx.send(RenderFrameEvent(pixels));
    }

    frameCount += 1;

    await Future.delayed(sleep);

    final current = DateTime.now();
    final elapsed = current.difference(prevDateTime);
    final fps = (1000 / elapsed.inMilliseconds).clamp(0, 80);

    sleep = Duration(
      milliseconds: max((sleep.inMilliseconds + (fps - 60.0)).floor(), 0),
    );

    fpsTotal += fps;

    if (frameCount >= 60) {
      parentTx.send(FpsUpdateEvent((fpsTotal / frameCount).floor()));

      frameCount = 0;
      fpsTotal = 0;
    }

    prevDateTime = current;
  }
}

class FpsUpdateEvent {
  FpsUpdateEvent(this.fps);

  final int fps;
}

class RenderFrameEvent {
  RenderFrameEvent(this.frame);

  final Uint8List frame;
}

class FileSelectedEvent {
  FileSelectedEvent(this.bytes);

  final Uint8List bytes;
}

class KeyPressedEvent {
  KeyPressedEvent(this.key);

  final JoypadKey key;
}

class KeyReleasedEvent {
  KeyReleasedEvent(this.key);

  final JoypadKey key;
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.image,
    required this.fps,
    required this.onRomSelected,
    required this.onKeyPressed,
    required this.onKeyReleased,
  }) : super(key: key);

  final ValueNotifier<int> fps;
  final ValueNotifier<ui.Image?> image;
  final void Function(Uint8List) onRomSelected;
  final void Function(JoypadKey) onKeyPressed;
  final void Function(JoypadKey) onKeyReleased;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DASH NES',
      theme: ThemeData(
        primaryColor: _primaryColor,
        canvasColor: _paddingColor,
      ),
      home: MyHomePage(
        title: 'DASH NES',
        fps: fps,
        image: image,
        onRomSelected: onRomSelected,
        onKeyPressed: onKeyPressed,
        onKeyReleased: onKeyReleased,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.fps,
    required this.image,
    required this.onRomSelected,
    required this.onKeyPressed,
    required this.onKeyReleased,
  }) : super(key: key);

  final String title;
  final ValueNotifier<int> fps;
  final ValueNotifier<ui.Image?> image;
  final void Function(Uint8List) onRomSelected;
  final void Function(JoypadKey) onKeyPressed;
  final void Function(JoypadKey) onKeyReleased;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final _keyToJoypadKeyMap = {
    LogicalKeyboardKey.keyZ: JoypadKey.A,
    LogicalKeyboardKey.keyX: JoypadKey.B,
    LogicalKeyboardKey.keyV: JoypadKey.Start,
    LogicalKeyboardKey.keyC: JoypadKey.Select,
    LogicalKeyboardKey.arrowUp: JoypadKey.Up,
    LogicalKeyboardKey.arrowDown: JoypadKey.Down,
    LogicalKeyboardKey.arrowRight: JoypadKey.Right,
    LogicalKeyboardKey.arrowLeft: JoypadKey.Left,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: _nesColor,
        title: Text(widget.title,
            style: const TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            )),
      ),
      body: KeyboardListener(
        onKeyEvent: (key) {
          final joypadKey = _keyToJoypadKeyMap[key.logicalKey];
          if (joypadKey == null) return;

          if (key is KeyDownEvent) {
            widget.onKeyPressed(joypadKey);
          }
          if (key is KeyUpEvent) {
            widget.onKeyReleased(joypadKey);
          }
        },
        focusNode: FocusNode(),
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(ui.Radius.circular(12.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ColoredBox(
                    color: _nesColor,
                    child: _LeftController(
                      onKeyPressed: widget.onKeyPressed,
                      onKeyReleased: widget.onKeyReleased,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _Screen(
                    fps: widget.fps,
                    image: widget.image,
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: _nesColor,
                    child: _RightController(
                      onKeyPressed: widget.onKeyPressed,
                      onKeyReleased: widget.onKeyReleased,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles();
            if (result == null) return;

            var bytes = result.files.first.bytes;

            if (bytes == null) {
              final file = File(result.paths.first!);

              bytes = await file.readAsBytes();
            }

            widget.onRomSelected(bytes);
          },
          backgroundColor: _seColor,
          child: const Icon(
            Icons.file_upload,
            color: Colors.white,
          )),
    );
  }
}

class _RightController extends StatelessWidget {
  const _RightController({
    Key? key,
    required this.onKeyPressed,
    required this.onKeyReleased,
  }) : super(key: key);

  final void Function(JoypadKey key) onKeyPressed;
  final void Function(JoypadKey key) onKeyReleased;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: 300,
        height: 400,
        child: Stack(
          children: [
            Positioned(
              top: 140,
              right: 40,
              width: 80,
              height: 50,
              child: _ControllerButton(
                onPressed: () => onKeyPressed(JoypadKey.A),
                onReleased: () => onKeyReleased(JoypadKey.A),
                color: _buttonColor,
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: 150,
              width: 80,
              height: 50,
              child: _ControllerButton(
                onPressed: () => onKeyPressed(JoypadKey.B),
                onReleased: () => onKeyReleased(JoypadKey.B),
                color: _buttonColor,
                child: const Text(
                  'B',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 50,
              right: 0,
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    height: 30,
                    child: _ControllerButton(
                      onPressed: () => onKeyPressed(JoypadKey.Select),
                      onReleased: () => onKeyReleased(JoypadKey.Select),
                      color: _seColor,
                      child: const Text(
                        'SELECT',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 30,
                    child: _ControllerButton(
                      onPressed: () => onKeyPressed(JoypadKey.Start),
                      onReleased: () => onKeyReleased(JoypadKey.Start),
                      color: _seColor,
                      child: const Text(
                        'START',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftController extends StatelessWidget {
  const _LeftController({
    Key? key,
    required this.onKeyPressed,
    required this.onKeyReleased,
  }) : super(key: key);

  final void Function(JoypadKey key) onKeyPressed;
  final void Function(JoypadKey key) onKeyReleased;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: 300,
        height: 400,
        child: Stack(
          children: [
            Positioned(
              top: 150,
              left: 30,
              width: 70,
              height: 70,
              child: _ControllerButton(
                onPressed: () => onKeyPressed(JoypadKey.Left),
                onReleased: () => onKeyReleased(JoypadKey.Left),
                color: _directionColor,
                child: const Icon(
                  Icons.arrow_left_rounded,
                  color: Colors.white,
                  semanticLabel: 'left',
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: 170,
              width: 70,
              height: 70,
              child: _ControllerButton(
                onPressed: () => onKeyPressed(JoypadKey.Right),
                onReleased: () => onKeyReleased(JoypadKey.Right),
                color: _directionColor,
                child: const Icon(
                  Icons.arrow_right_rounded,
                  color: Colors.white,
                  semanticLabel: 'right',
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 100,
              width: 70,
              height: 70,
              child: _ControllerButton(
                onPressed: () => onKeyPressed(JoypadKey.Up),
                onReleased: () => onKeyReleased(JoypadKey.Up),
                color: _directionColor,
                child: const Icon(
                  Icons.arrow_drop_up_sharp,
                  color: Colors.white,
                  semanticLabel: 'up',
                ),
              ),
            ),
            Positioned(
              top: 220,
              left: 100,
              width: 70,
              height: 70,
              child: _ControllerButton(
                onPressed: () => onKeyPressed(JoypadKey.Down),
                onReleased: () => onKeyReleased(JoypadKey.Down),
                color: _directionColor,
                child: const Icon(
                  Icons.arrow_drop_down_sharp,
                  color: Colors.white,
                  semanticLabel: 'down',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Screen extends StatefulWidget {
  const _Screen({
    Key? key,
    required this.fps,
    required this.image,
  }) : super(key: key);

  final ValueNotifier<int> fps;
  final ValueNotifier<ui.Image?> image;

  @override
  State<StatefulWidget> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  @override
  void initState() {
    super.initState();

    widget.image.addListener(_rebuild);
  }

  @override
  void dispose() {
    super.dispose();
    widget.image.removeListener(_rebuild);
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paddingColor,
      child: FittedBox(
        child: Card(
          elevation: 10,
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _ScreenPainter(
              image: widget.image.value,
            ),
            child: SizedBox(
              width: _width,
              height: _height,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.fps.value.toString(),
                    style: const TextStyle(
                      color: _primaryColor,
                      fontSize: 6.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControllerButton extends StatelessWidget {
  const _ControllerButton({
    Key? key,
    required this.color,
    required this.onPressed,
    required this.onReleased,
    required this.child,
  }) : super(key: key);

  final Color color;
  final void Function() onPressed;
  final void Function() onReleased;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        child: Container(
          padding: const EdgeInsets.all(2.0),
          color: _primaryColor,
          child: Material(
            color: color,
            elevation: 5,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            child: InkWell(
              onTapDown: (_) => onPressed(),
              onTap: () => onReleased(),
              onTapCancel: () => onReleased(),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenPainter extends CustomPainter {
  const _ScreenPainter({
    required this.image,
  });

  final ui.Image? image;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = Paint()..color = _screenColor;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    if (image != null) {
      canvas.drawImageRect(
        image!,
        const Rect.fromLTWH(0, 0, _width, _height),
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
