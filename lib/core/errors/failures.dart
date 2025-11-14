abstract class Failure {
  final String message;

  Failure(this.message);

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  final String? code;

  ServerFailure(super.message, {this.code});
}

class AuthenticationFailure extends Failure {
  AuthenticationFailure(super.message);
}

class UnknownFailure extends Failure {
  UnknownFailure(super.message);
}
