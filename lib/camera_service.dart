import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static List<CameraDescription> cameras = [];
  
  static Future<void> initialize() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      cameras = await availableCameras();
    }
  }
  
  static CameraDescription get frontCamera {
    return cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }
  
  static bool get hasCamera => cameras.isNotEmpty;
  
  static bool get hasFrontCamera => 
    cameras.any((camera) => camera.lensDirection == CameraLensDirection.front);
}
