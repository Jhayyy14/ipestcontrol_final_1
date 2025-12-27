import 'dart:async';
import 'rpi_service.dart';

/// UI Adapter for backward compatibility
/// ⚠️ DOES NOT change RpiService logic
class RpiServiceAdapter {
  final RpiService _service = RpiService();

  /// ============================
  /// LEGACY METHOD MAPPINGS
  /// ============================

  /// Old name → new implementation
  Future<bool> scanAndConnect() async {
    return await _service.connectAuto();
  }

  /// Legacy stop (UI-only)
  void stopStreaming() {
    // No-op: stream stops when UI stops using videoFeedUrl
  }

  /// Legacy shutdown (optional no-op)
  Future<void> shutdownSystem() async {
    // Not supported in new service
    return;
  }

  /// Legacy system modes (no-op)
  void setSystemModes(bool pestMode, bool detectionMode) {
    // Not supported anymore
  }

  /// ============================
  /// LEGACY GETTERS
  /// ============================

  String? get rpiIpAddress => _service.rpiIpAddress;

  String? get connectionMode => _service.connectionMode;

  /// Fake battery stream so old screens compile
  Stream<Map<String, dynamic>> get batteryStream =>
      const Stream.empty();

  /// Expose real service if needed
  RpiService get raw => _service;
}
  