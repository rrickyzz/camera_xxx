import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'package:flutter_animate/flutter_animate.dart';

// Future<void> main() async {
//   // Ensure that plugin services are initialized so that `availableCameras()`
//   // can be called before `runApp()`
//   WidgetsFlutterBinding.ensureInitialized();

//   // Obtain a list of the available cameras on the device.
//   final cameras = await availableCameras();

//   // Get a specific camera from the list of available cameras.
//   final firstCamera = cameras.first;

//   runApp(
//     MaterialApp(
//       theme: ThemeData.dark(),
//       home: TakeVideoScreen(
//         // Pass the appropriate camera to the TakeVideoScreen widget.
//         camera: firstCamera,
//       ),
//     ),
//   );
// }

// A screen that allows users to take a picture using a given camera.
class TakeVideoScreen extends StatefulWidget {
  const TakeVideoScreen(
      {super.key, required this.camera, required this.onSaved});

  final CameraDescription camera;
  final Function(XFile file) onSaved;

  @override
  TakeVideoScreenState createState() => TakeVideoScreenState();
}

class TakeVideoScreenState extends State<TakeVideoScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _seconds = 0;
  int _seconds2 = 5;
  bool promptVisible = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsFlutterBinding.ensureInitialized();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    int duration = 10;
    int counter = 0;
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (counter < duration) {
          setState(() {
            _seconds = counter;
          });
          counter++;
        } else {
          timer.cancel();
        }
      },
    );
  }

  void _startTimePrompt() {
    const oneSec = Duration(seconds: 1);
    int duration2 = 0;
    int counter2 = 5;
    _timer = Timer.periodic(
      oneSec,
      (Timer timer2) {
        if (counter2 > duration2) {
          setState(() {
            _seconds2 = counter2;
          });
          counter2--;
        } else {
          timer2.cancel();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized || cameraController == null) {
      return;
    }
    if (state == AppLifecycleState.detached) {
      cameraController.dispose();
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (cameraController != null) {
        // If the controller is updated then update the UI.
        cameraController.addListener(() {
          if (mounted) setState(() {});
          if (cameraController.value.hasError) {
            print('Camera error ${cameraController.value.errorDescription}');
          }
        });

        cameraController.initialize();
      }
      //_initializeCameraController(cameraController.description);
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.

    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                if (!_controller.value.isInitialized) {
                  return Container();
                }
                return CameraPreview(_controller);
              } else {
                // Otherwise, display a loading indicator.
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Visibility(
              visible: _controller.value.isRecordingVideo,
              child: Text(
                'Recording :00:0$_seconds',
                style: const TextStyle(color: Colors.green, fontSize: 18),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Visibility(
              visible: promptVisible,
              child: Text(
                'Video recording will in start  $_seconds2 seconds.. ',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ).animate().shake(),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 50.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            // Provide an onPressed callback.
            onPressed: () async {
              setState(() {
                promptVisible = true;
                _startTimePrompt();
              });
              // Take the Picture in a try / catch block. If anything goes wrong,
              // catch the error.
              try {
                // Ensure that the camera is initialized.
                await _initializeControllerFuture;

                // Attempt to take a picture and get the file `image`
                // where it was saved.
                // final image = await _controller.takePicture();
                if (_controller.value.isRecordingVideo) {
                  return;
                }

                await Future.delayed(const Duration(seconds: 7), () async {
                  setState(() {
                    promptVisible = false;
                    _controller.startVideoRecording();
                    _startTimer();
                  });
                });

                await Future.delayed(const Duration(seconds: 12), () async {
                  XFile xfile = await _controller.stopVideoRecording();
                  await _controller.pausePreview();

                  widget.onSaved(xfile);
                });
                if (!mounted) return;

                // If the picture was taken, display it on a new screen.
                // await Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => DisplayPictureScreen(
                //       // Pass the automatically generated path to
                //       // the DisplayPictureScreen widget.
                //       imagePath: image.path,
                //     ),
                //   ),
                // );
              } catch (e) {
                // If an error occurs, log the error to the console.
                dev.log(e.toString());
              }
            },
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayVideoScreen extends StatelessWidget {
  final String imagePath;

  const DisplayVideoScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
