import 'package:connectivity_plus/connectivity_plus.dart';

/// Exposes online/offline state as a stream and a one-shot check. Feature
/// repositories use this to decide between remote and cached reads and to flush
/// the offline sync queue on reconnect.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map((results) => _isOnline(results));

  Future<bool> get isOnline async =>
      _isOnline(await _connectivity.checkConnectivity());

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
