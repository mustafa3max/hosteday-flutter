import 'package:hosteday_flutter/hosteday_flutter.dart';

/// Converts SDK and unexpected errors into readable UI messages.
class ErrorPresenter {
  const ErrorPresenter._();

  static String messageFrom(Object error) {
    if (error is HosteDayException) {
      return error.displayMessage;
    }

    return error.toString();
  }
}
