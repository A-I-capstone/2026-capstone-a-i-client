class ChatResponse {
  final bool isSuccess;
  final String message;
  final String? errorCode;

  const ChatResponse({
    required this.isSuccess,
    required this.message,
    this.errorCode,
  });

  factory ChatResponse.success(String message) {
    return ChatResponse(
      isSuccess: true,
      message: message,
    );
  }

  factory ChatResponse.error({
    required String message,
    String? errorCode,
  }) {
    return ChatResponse(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
}
