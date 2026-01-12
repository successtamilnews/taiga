import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum LogLevel {
  debug('DEBUG', 0),
  info('INFO', 1),
  warning('WARNING', 2),
  error('ERROR', 3),
  critical('CRITICAL', 4);

  const LogLevel(this.name, this.priority);
  final String name;
  final int priority;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.metadata,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'tag': tag,
      'metadata': metadata,
      'stack_trace': stackTrace,
      'app_type': 'seller',
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      tag: json['tag'],
      metadata: json['metadata'],
      stackTrace: json['stack_trace'],
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name}] ');
    if (tag != null) buffer.write('[$tag] ');
    buffer.write(message);
    if (metadata != null) {
      buffer.write(' | Metadata: ${jsonEncode(metadata)}');
    }
    if (stackTrace != null) {
      buffer.write('\nStack Trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final Dio _dio = Dio();
  bool _isInitialized = false;
  
  // Configuration
  LogLevel _minLevel = LogLevel.debug;
  bool _enableConsoleLogging = kDebugMode;
  bool _enableFileLogging = true;
  bool _enableRemoteLogging = false;
  bool _enableCrashReporting = true;
  
  // Remote logging
  String? _remoteEndpoint;
  String? _authToken;
  Duration _uploadInterval = const Duration(minutes: 5);
  int _maxBatchSize = 50;
  
  // File logging
  File? _logFile;
  int _maxFileSize = 10 * 1024 * 1024; // 10MB
  int _maxFiles = 5;
  
  // In-memory buffer
  final List<LogEntry> _logBuffer = [];
  int _maxBufferSize = 1000;
  
  // Device info
  Map<String, dynamic> _deviceInfo = {};

  // Getters
  List<LogEntry> get logs => List.unmodifiable(_logBuffer);
  LogLevel get minLevel => _minLevel;
  bool get isInitialized => _isInitialized;

  // Initialize logging service
  Future<void> initialize({
    LogLevel? minLevel,
    bool? enableConsoleLogging,
    bool? enableFileLogging,
    bool? enableRemoteLogging,
    bool? enableCrashReporting,
    String? remoteEndpoint,
    String? authToken,
    Duration? uploadInterval,
    int? maxBatchSize,
    int? maxBufferSize,
    int? maxFileSize,
    int? maxFiles,
  }) async {
    if (_isInitialized) return;

    // Set configuration
    _minLevel = minLevel ?? _minLevel;
    _enableConsoleLogging = enableConsoleLogging ?? _enableConsoleLogging;
    _enableFileLogging = enableFileLogging ?? _enableFileLogging;
    _enableRemoteLogging = enableRemoteLogging ?? _enableRemoteLogging;
    _enableCrashReporting = enableCrashReporting ?? _enableCrashReporting;
    _remoteEndpoint = remoteEndpoint;
    _authToken = authToken;
    _uploadInterval = uploadInterval ?? _uploadInterval;
    _maxBatchSize = maxBatchSize ?? _maxBatchSize;
    _maxBufferSize = maxBufferSize ?? _maxBufferSize;
    _maxFileSize = maxFileSize ?? _maxFileSize;
    _maxFiles = maxFiles ?? _maxFiles;

    // Setup device info
    await _setupDeviceInfo();

    // Setup file logging
    if (_enableFileLogging) {
      await _setupFileLogging();
    }

    // Setup remote logging
    if (_enableRemoteLogging) {
      _setupRemoteLogging();
    }

    // Setup crash reporting
    if (_enableCrashReporting) {
      _setupCrashReporting();
    }

    _isInitialized = true;

    log(LogLevel.info, 'Logging service initialized for Seller App', tag: 'LoggingService', metadata: {
      'min_level': _minLevel.name,
      'console_logging': _enableConsoleLogging,
      'file_logging': _enableFileLogging,
      'remote_logging': _enableRemoteLogging,
      'crash_reporting': _enableCrashReporting,
      'app_type': 'seller',
    });
  }

  // Main logging method
  void log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check minimum level
    if (level.priority < _minLevel.priority) return;

    // Create log entry
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      metadata: {
        ..._deviceInfo,
        'app_type': 'seller',
        ...?metadata,
        if (error != null) 'error': error.toString(),
      },
      stackTrace: stackTrace?.toString(),
    );

    // Add to buffer
    _addToBuffer(entry);

    // Console logging
    if (_enableConsoleLogging) {
      _logToConsole(entry);
    }

    // File logging
    if (_enableFileLogging && _logFile != null) {
      _logToFile(entry);
    }

    // Remote logging for warnings and errors
    if (_enableRemoteLogging && level.priority >= LogLevel.warning.priority) {
      _scheduleRemoteUpload();
    }
  }

  // Convenience methods
  void debug(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.debug, message, tag: tag, metadata: metadata);
  }

  void info(String message, {String? tag, Map<String, dynamic>? metadata}) {
    log(LogLevel.info, message, tag: tag, metadata: metadata);
  }

  void warning(String message, {String? tag, Map<String, dynamic>? metadata, Object? error}) {
    log(LogLevel.warning, message, tag: tag, metadata: metadata, error: error);
  }

  void error(String message, {String? tag, Map<String, dynamic>? metadata, Object? error, StackTrace? stackTrace}) {
    log(LogLevel.error, message, tag: tag, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  void critical(String message, {String? tag, Map<String, dynamic>? metadata, Object? error, StackTrace? stackTrace}) {
    log(LogLevel.critical, message, tag: tag, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  // Seller-specific logging methods
  void logSellerAction({
    required String action,
    String? sellerId,
    String? orderId,
    String? productId,
    Map<String, dynamic>? metadata,
  }) {
    info(
      'Seller Action: $action',
      tag: 'SellerAction',
      metadata: {
        'action': action,
        'seller_id': sellerId,
        'order_id': orderId,
        'product_id': productId,
        ...?metadata,
      },
    );
  }

  void logOrderManagement({
    required String action,
    required String orderId,
    String? customerId,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    info(
      'Order Management: $action for order $orderId',
      tag: 'OrderManagement',
      metadata: {
        'action': action,
        'order_id': orderId,
        'customer_id': customerId,
        'status': status,
        ...?metadata,
      },
    );
  }

  void logInventoryUpdate({
    required String productId,
    required String action,
    int? oldQuantity,
    int? newQuantity,
    Map<String, dynamic>? metadata,
  }) {
    info(
      'Inventory Update: $action for product $productId',
      tag: 'InventoryUpdate',
      metadata: {
        'product_id': productId,
        'action': action,
        'old_quantity': oldQuantity,
        'new_quantity': newQuantity,
        'quantity_change': newQuantity != null && oldQuantity != null 
          ? newQuantity - oldQuantity 
          : null,
        ...?metadata,
      },
    );
  }

  void logSalesData({
    required String orderId,
    required double amount,
    required String paymentMethod,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) {
    info(
      'Sale Completed: Order $orderId - \$${amount.toStringAsFixed(2)}',
      tag: 'SalesData',
      metadata: {
        'order_id': orderId,
        'sale_amount': amount,
        'payment_method': paymentMethod,
        'customer_id': customerId,
        ...?metadata,
      },
    );
  }

  void logCustomerInteraction({
    required String interactionType,
    required String customerId,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    info(
      'Customer Interaction: $interactionType with customer $customerId',
      tag: 'CustomerInteraction',
      metadata: {
        'interaction_type': interactionType,
        'customer_id': customerId,
        'order_id': orderId,
        ...?metadata,
      },
    );
  }

  void logPromotionActivity({
    required String action,
    required String promotionId,
    String? promotionType,
    Map<String, dynamic>? metadata,
  }) {
    info(
      'Promotion Activity: $action for promotion $promotionId',
      tag: 'PromotionActivity',
      metadata: {
        'action': action,
        'promotion_id': promotionId,
        'promotion_type': promotionType,
        ...?metadata,
      },
    );
  }

  void logStoreConfiguration({
    required String configType,
    required String action,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) {
    info(
      'Store Configuration: $action for $configType',
      tag: 'StoreConfig',
      metadata: {
        'config_type': configType,
        'action': action,
        'old_values': oldValues,
        'new_values': newValues,
      },
    );
  }

  // Network logging
  void logNetworkRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
    int? statusCode,
    String? responseBody,
    int? duration,
    Object? error,
  }) {
    log(
      error != null ? LogLevel.error : LogLevel.debug,
      'Network ${error != null ? 'Error' : 'Request'}: $method $url',
      tag: 'Network',
      metadata: {
        'method': method,
        'url': url,
        'headers': headers,
        'request_body': body?.toString(),
        'status_code': statusCode,
        'response_body': responseBody,
        'duration_ms': duration,
        if (error != null) 'error': error.toString(),
      },
      error: error,
    );
  }

  // Performance logging
  void logPerformance({
    required String operation,
    required int durationMs,
    Map<String, dynamic>? metadata,
  }) {
    log(
      LogLevel.info,
      'Performance: $operation took ${durationMs}ms',
      tag: 'Performance',
      metadata: {
        'operation': operation,
        'duration_ms': durationMs,
        ...?metadata,
      },
    );
  }

  // Business logic logging
  void logBusinessEvent({
    required String event,
    Map<String, dynamic>? metadata,
  }) {
    log(
      LogLevel.info,
      'Business Event: $event',
      tag: 'Business',
      metadata: metadata,
    );
  }

  // Security logging
  void logSecurityEvent({
    required String event,
    String? userId,
    String? ipAddress,
    Map<String, dynamic>? metadata,
  }) {
    log(
      LogLevel.warning,
      'Security Event: $event',
      tag: 'Security',
      metadata: {
        'event': event,
        'user_id': userId,
        'ip_address': ipAddress,
        ...?metadata,
      },
    );
  }

  // Log filtering and querying
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logBuffer.where((entry) => entry.level == level).toList();
  }

  List<LogEntry> getLogsByTag(String tag) {
    return _logBuffer.where((entry) => entry.tag == tag).toList();
  }

  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return _logBuffer.where((entry) =>
        entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end)).toList();
  }

  List<LogEntry> searchLogs(String query) {
    return _logBuffer.where((entry) =>
        entry.message.toLowerCase().contains(query.toLowerCase()) ||
        (entry.tag?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();
  }

  // Export logs
  Future<String> exportLogs({
    LogLevel? minLevel,
    String? tag,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var logs = _logBuffer.asMap().entries;

    // Apply filters
    if (minLevel != null) {
      logs = logs.where((entry) => entry.value.level.priority >= minLevel.priority);
    }
    if (tag != null) {
      logs = logs.where((entry) => entry.value.tag == tag);
    }
    if (startDate != null) {
      logs = logs.where((entry) => entry.value.timestamp.isAfter(startDate));
    }
    if (endDate != null) {
      logs = logs.where((entry) => entry.value.timestamp.isBefore(endDate));
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Seller App Logs Export ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${logs.length}');
    buffer.writeln('=====================================\n');
    
    for (final logEntry in logs) {
      buffer.writeln(logEntry.value.toString());
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  Future<File> exportLogsToFile({
    LogLevel? minLevel,
    String? tag,
    DateTime? startDate,
    DateTime? endDate,
    String? fileName,
  }) async {
    final content = await exportLogs(
      minLevel: minLevel,
      tag: tag,
      startDate: startDate,
      endDate: endDate,
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${fileName ?? 'seller_logs_export_${DateTime.now().millisecondsSinceEpoch}.txt'}');
    
    await file.writeAsString(content);
    return file;
  }

  // Configuration methods
  void setMinLevel(LogLevel level) {
    _minLevel = level;
    info('Log level changed to ${level.name}', tag: 'LoggingService');
  }

  void enableConsoleLogging(bool enabled) {
    _enableConsoleLogging = enabled;
  }

  void enableFileLogging(bool enabled) {
    _enableFileLogging = enabled;
  }

  void enableRemoteLogging(bool enabled) {
    _enableRemoteLogging = enabled;
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  // Buffer management
  void clearLogs() {
    _logBuffer.clear();
    info('Log buffer cleared', tag: 'LoggingService');
  }

  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    
    // Maintain buffer size
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  // Console logging with color coding
  void _logToConsole(LogEntry entry) {
    switch (entry.level) {
      case LogLevel.debug:
        debugPrint('\x1B[36m${entry.toString()}\x1B[0m'); // Cyan
        break;
      case LogLevel.info:
        debugPrint('\x1B[32m${entry.toString()}\x1B[0m'); // Green
        break;
      case LogLevel.warning:
        debugPrint('\x1B[33m${entry.toString()}\x1B[0m'); // Yellow
        break;
      case LogLevel.error:
        debugPrint('\x1B[31m${entry.toString()}\x1B[0m'); // Red
        break;
      case LogLevel.critical:
        debugPrint('\x1B[35m${entry.toString()}\x1B[0m'); // Magenta
        break;
    }
  }

  // File logging setup
  Future<void> _setupFileLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs/seller');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      _logFile = File('${logsDir.path}/seller_app_${DateTime.now().toIso8601String().split('T')[0]}.log');
      
      // Rotate logs if needed
      await _rotateLogs();
    } catch (e) {
      debugPrint('Failed to setup file logging: $e');
    }
  }

  void _logToFile(LogEntry entry) {
    try {
      _logFile?.writeAsStringSync(
        '${entry.toString()}\n',
        mode: FileMode.append,
      );
      
      // Check file size and rotate if needed
      _checkAndRotateFile();
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  Future<void> _rotateLogs() async {
    if (_logFile == null) return;
    
    try {
      final directory = _logFile!.parent;
      final files = directory.listSync()
          .where((f) => f is File && f.path.endsWith('.log'))
          .cast<File>()
          .toList();
      
      // Sort by modification date
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Delete old files if we have too many
      if (files.length >= _maxFiles) {
        for (int i = _maxFiles - 1; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to rotate logs: $e');
    }
  }

  void _checkAndRotateFile() {
    try {
      if (_logFile?.lengthSync() ?? 0 > _maxFileSize) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final newFileName = 'seller_app_${tomorrow.toIso8601String().split('T')[0]}.log';
        _logFile = File('${_logFile!.parent.path}/$newFileName');
      }
    } catch (e) {
      debugPrint('Failed to check file size: $e');
    }
  }

  // Remote logging
  void _setupRemoteLogging() {
    if (_remoteEndpoint == null) return;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
    ));

    _schedulePeriodicUpload();
  }

  void _scheduleRemoteUpload() {
    if (_enableRemoteLogging) {
      Future.delayed(Duration.zero, _uploadLogs);
    }
  }

  void _schedulePeriodicUpload() {
    Future.delayed(_uploadInterval, () async {
      await _uploadLogs();
      if (_enableRemoteLogging) {
        _schedulePeriodicUpload();
      }
    });
  }

  Future<void> _uploadLogs() async {
    if (_remoteEndpoint == null || _logBuffer.isEmpty) return;

    try {
      final logsToUpload = _logBuffer
          .where((entry) => entry.level.priority >= LogLevel.warning.priority)
          .take(_maxBatchSize)
          .map((entry) => entry.toJson())
          .toList();

      if (logsToUpload.isNotEmpty) {
        await _dio.post(
          '$_remoteEndpoint/logs/seller',
          data: {
            'logs': logsToUpload,
            'device_info': _deviceInfo,
            'app_type': 'seller',
          },
        );

        debug('Uploaded ${logsToUpload.length} logs to remote server', tag: 'LoggingService');
      }
    } catch (e) {
      debugPrint('Failed to upload logs: $e');
    }
  }

  // Crash reporting
  void _setupCrashReporting() {
    FlutterError.onError = (FlutterErrorDetails details) {
      critical(
        'Flutter Error in Seller App: ${details.exception}',
        tag: 'CrashReporter',
        metadata: {
          'library': details.library,
          'context': details.context?.toString(),
          'app_type': 'seller',
        },
        error: details.exception,
        stackTrace: details.stack,
      );
    };
  }

  // Device info
  Future<void> _setupDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'app_type': 'seller',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
          'app_type': 'seller',
        };
      } else {
        _deviceInfo = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'app_type': 'seller',
        };
      }
    } catch (e) {
      _deviceInfo = {
        'platform': 'Unknown',
        'error': e.toString(),
        'app_type': 'seller',
      };
    }
  }

  // Cleanup
  Future<void> dispose() async {
    if (_enableRemoteLogging) {
      await _uploadLogs();
    }
    
    _logBuffer.clear();
    _isInitialized = false;
  }
}