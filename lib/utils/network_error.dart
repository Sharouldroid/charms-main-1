import 'package:http/http.dart' as http;

/// True when [error] represents a lost/failed network connection.
/// Matches dart:io's SocketException by runtime-type name (rather than
/// importing dart:io directly) so this check stays valid on web, where
/// failed requests surface as [http.ClientException] instead.
bool isNetworkError(Object error) {
  return error is http.ClientException ||
      error.runtimeType.toString() == 'SocketException';
}
