import 'package:url_launcher/url_launcher.dart';

Future<void> downloadFile(int userId) async {
  final downloadUrl =
      'http://localhost/internship1/download.php?userId=$userId';
  if (await canLaunch(downloadUrl)) {
    await launch(downloadUrl);
  } else {
    throw 'Could not launch $downloadUrl';
  }
}
