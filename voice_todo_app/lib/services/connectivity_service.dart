import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus {
  online,
  offline,
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<ConnectivityResult>? _subscription;
  NetworkStatus _lastStatus = NetworkStatus.offline;

  Stream<NetworkStatus> get onStatusChange => _controller.stream;
  NetworkStatus get currentStatus => _lastStatus;

  ConnectivityService() {
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(ConnectivityResult result) {
    NetworkStatus status;
    
    switch (result) {
      case ConnectivityResult.mobile:
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.vpn:
        status = NetworkStatus.online;
        break;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.none:
      default:
        status = NetworkStatus.offline;
        break;
    }
    
    if (status != _lastStatus) {
      _lastStatus = status;
      _controller.add(status);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
} 