import 'package:logger/logger.dart';

/// Emit metadata-only diagnostics without changing a network outcome when a
/// logger/filter/printer has been disposed or throws. Never fall back to print:
/// logging exceptions and their stacks may themselves contain credentials.
void logNetworkMetadata(Logger? logger, Level level, String message) {
  try {
    switch (level) {
      case Level.info:
        logger?.i(message);
      case Level.warning:
        logger?.w(message);
      case Level.error:
        logger?.e(message);
      default:
        logger?.log(level, message);
    }
  } catch (_) {
    // Diagnostics are best-effort, not part of the transport contract.
  }
}
