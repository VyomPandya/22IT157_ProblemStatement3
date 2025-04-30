import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus {
  online,
  offline,
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
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

  void _updateStatus(List<ConnectivityResult> results) {
    // If the list is empty, assume offline
    if (results.isEmpty) {
      _setNetworkStatus(NetworkStatus.offline);
      return;
    }

    // Check if any connectivity option indicates online status
    bool hasConnection = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );

    _setNetworkStatus(hasConnection ? NetworkStatus.online : NetworkStatus.offline);
  }

  void _setNetworkStatus(NetworkStatus status) {
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