// lib/blocs/auth/auth_event.dart

abstract class AuthEvent {}

// Event for requesting login
class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  LoginRequested({required this.username, required this.password});
}

//event for registering a new user
class RegisterRequested extends AuthEvent {
  final String username;
  final String password;

  RegisterRequested({required this.username, required this.password});
}

class LoginWithGoogleRequested extends AuthEvent {}

class LoginWithFacebookRequested extends AuthEvent {}

// Event for requesting logout
class LogoutRequested extends AuthEvent {}