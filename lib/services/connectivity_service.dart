// connectivity_service.dart
// Service to monitor network connectivity status
// This checks ACTUAL internet access, not just WiFi/data on/off
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = 
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  
  // IMPORTANT: Start as null (unknown) not true
  bool? _isConnected;
  bool get isConnected => _isConnected ?? false; // Default to false if unknown
  
  bool _initialized = false;
  Timer? _periodicChecker;

  // Initialize the connectivity listener
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    // debugPrint('📶 ConnectivityService initializing...');
    
    // Listen for network changes (WiFi/data on/off)
    _connectivity.onConnectivityChanged.listen(_onNetworkChanged);
    
    // Do initial check IMMEDIATELY and WAIT for result
    await _doFullCheck();
    
    // Periodic check every 8 seconds
    _periodicChecker = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _doFullCheck(),
    );
    
    // debugPrint('📶 ConnectivityService initialized. Current status: ${_isConnected == true ? "ONLINE" : "OFFLINE"}');
  }

  // Called when network state changes (WiFi/data toggled)
  void _onNetworkChanged(List<ConnectivityResult> results) async {
    final hasNetwork = !results.contains(ConnectivityResult.none);
    // debugPrint('📶 Network state changed: ${results.map((r) => r.name).join(", ")}');
    
    if (!hasNetwork) {
      // No network interface at all - definitely offline
      _updateStatus(false);
    } else {
      // Has network interface - check if it actually works
      await _doFullCheck();
    }
  }

  // Full connectivity check
  Future<void> _doFullCheck() async {
    final hasInternet = await _testInternetConnection();
    _updateStatus(hasInternet);
  }

  // Update connection status and ALWAYS notify listeners
  void _updateStatus(bool connected) {
    final changed = _isConnected != connected;
    _isConnected = connected;
    
    // ALWAYS broadcast current state (not just on change)
    _connectionStatusController.add(connected);
    
    if (changed) {
      // debugPrint('📶 Status CHANGED: ${connected ? "✅ ONLINE" : "❌ OFFLINE"}');
    }
  }

  // Test actual internet connectivity using multiple methods
  Future<bool> _testInternetConnection() async {
    // debugPrint('📶 Testing internet connection...');
    
    // Method 1: Try HTTP request to a reliable endpoint
    if (await _tryHttpRequest()) {
      // debugPrint('📶 HTTP check: SUCCESS');
      return true;
    }
    
    // debugPrint('📶 All checks FAILED - no internet');
    return false;
  }

  // Try HTTP request to check connectivity
  Future<bool> _tryHttpRequest() async {
    final testUrls = [
      'https://www.google.com/generate_204',
      'https://clients3.google.com/generate_204',
      'https://connectivitycheck.gstatic.com/generate_204',
      'https://www.cloudflare.com/cdn-cgi/trace',
    ];
    
    for (final url in testUrls) {
      try {
        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      } catch (e) {
        // Try next URL
        continue;
      }
    }
    return false;
  }

  // Public method to check current connectivity
  Future<bool> checkConnectivity() async {
    await _doFullCheck();
    return _isConnected ?? false;
  }

  // Force an immediate check (useful after user actions)
  Future<bool> forceCheck() async {
    // debugPrint('📶 Force checking internet...');
    await _doFullCheck();
    return _isConnected ?? false;
  }

  // Dispose resources
  void dispose() {
    _periodicChecker?.cancel();
    _connectionStatusController.close();
  }

  // Show no connection dialog
  static void showNoConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.wifi_off_rounded,
          size: 48,
          color: Colors.red,
        ),
        title: const Text(
          'No Internet Connection',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Please check your internet connection and try again.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show connection restored snackbar
  static void showConnectionRestoredSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 12),
            Text('Connection restored'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Offline Banner Widget - Shows "OFFLINE" at top of screen
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.red,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'NO INTERNET CONNECTION',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to wrap the ENTIRE app with connectivity monitoring
/// This shows an offline banner at the top when connection is lost
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<bool> _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Initialize and listen to connectivity changes
    ConnectivityService().initialize();
    _isOnline = ConnectivityService().isConnected;
    
    _subscription = ConnectivityService().connectionStatusStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
        
        // Show snackbar when connection is restored
        if (isConnected && !_isOnline) {
          ConnectivityService.showConnectionRestoredSnackbar(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner at top
        if (!_isOnline) const OfflineBanner(),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Alternative: Material Banner style (appears below AppBar)
class ConnectivityAwareScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const ConnectivityAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  State<ConnectivityAwareScaffold> createState() => _ConnectivityAwareScaffoldState();
}

class _ConnectivityAwareScaffoldState extends State<ConnectivityAwareScaffold> {
  StreamSubscription<bool>? _subscription;
  bool _isOnline = false; // Start as FALSE (assume offline until proven online)
  bool _isChecking = true; // Start as checking
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Initialize the service and WAIT for first check
    await ConnectivityService().initialize();
    
    if (!mounted) return;
    
    // Get the actual status after initialization
    setState(() {
      _isOnline = ConnectivityService().isConnected;
      _isChecking = false;
      _initialized = true;
    });
    
    // debugPrint('📶 UI initialized with status: ${_isOnline ? "ONLINE" : "OFFLINE"}');
    
    // Listen for future changes
    _subscription = ConnectivityService().connectionStatusStream.listen((isConnected) {
      // debugPrint('📶 UI received status update: ${isConnected ? "ONLINE" : "OFFLINE"}');
      if (mounted) {
        final wasOffline = !_isOnline;
        setState(() {
          _isOnline = isConnected;
          _isChecking = false;
        });
        
        // Show snackbar when coming back online
        if (isConnected && wasOffline && _initialized) {
          ConnectivityService.showConnectionRestoredSnackbar(context);
        }
      }
    });
  }

  Future<void> _checkConnection() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    final result = await ConnectivityService().forceCheck();
    
    if (mounted) {
      setState(() {
        _isOnline = result;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      drawer: widget.drawer,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      backgroundColor: widget.backgroundColor,
      body: Column(
        children: [
          // Offline banner with tap to retry
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isOnline ? 0 : 52,
            child: _isOnline 
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.red.shade700,
                  child: InkWell(
                    onTap: _checkConnection,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            'No internet connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (_isChecking)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to retry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
          // Main body
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}
