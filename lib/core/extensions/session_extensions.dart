import '../../domain/entities/session.dart';

extension SessionTypeLabel on SessionType {
  String get label {
    switch (this) {
      case SessionType.questionBox:
        return 'Response Box';
      case SessionType.poll:
        return 'Poll';
      case SessionType.mixedMode:
        return 'Mixed Mode';
    }
  }
}
