class DeserializationError implements Exception {
  final String message;

  DeserializationError(this.message);
}

typedef ReconnectId = String;
