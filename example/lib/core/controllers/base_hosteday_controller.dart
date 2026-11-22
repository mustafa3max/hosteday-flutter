import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Base controller providing standard reactive state for loading and error management.
abstract class BaseHostedayController extends GetxController {
  /// Whether an asynchronous operation is in progress.
  final RxBool isLoading = false.obs;

  /// Holds the last error message or empty string.
  final RxString errorMessage = ''.obs;

  /// Whether there is currently an error.
  bool get hasError => errorMessage.value.isNotEmpty;

  /// Clears the current error state.
  void clearError() {
    errorMessage.value = '';
  }

  /// Sets an explicit error message.
  void setError(String message) {
    errorMessage.value = message;
  }

  /// Executes an async action with automatic [isLoading] and error capture.
  Future<T?> runWithLoading<T>(
    Future<T> Function() action, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool rethrowError = false,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await action();
      return result;
    } catch (error, stackTrace) {
      errorMessage.value = error.toString();
      if (onError != null) {
        onError(error, stackTrace);
      }
      if (rethrowError) {
        rethrow;
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Displays an error snackbar using GetX.
  void showErrorSnackbar({String title = 'Error', required String message}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  /// Displays a success snackbar using GetX.
  void showSuccessSnackbar({
    String title = 'Success',
    required String message,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}
