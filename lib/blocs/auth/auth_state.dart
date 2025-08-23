// lib/blocs/auth/auth_state.dart

abstract class AuthState {}

// Trạng thái ban đầu, khi ứng dụng vừa khởi động
class AuthInitial extends AuthState {}

// Trạng thái đang xử lý yêu cầu xác thực
class AuthLoading extends AuthState {}

// Trạng thái đã xác thực thành công
class AuthAuthenticated extends AuthState {
  final String token;
  AuthAuthenticated(this.token);
}

// Trạng thái chưa xác thực (sau khi đăng xuất hoặc phiên hết hạn)
class AuthUnauthenticated extends AuthState {}

// Trạng thái khi có lỗi xảy ra trong quá trình xác thực
class AuthError extends AuthState {
  final String? message;
  AuthError({this.message});
}
