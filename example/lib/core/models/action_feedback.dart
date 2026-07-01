/// نتيجة عملية تحتاج رسالة فورية في الواجهة، مثل SnackBar.
class ActionFeedback {
  const ActionFeedback({required this.message, this.isError = false});

  final String message;
  final bool isError;
}
