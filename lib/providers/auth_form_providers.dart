import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginFormState {
  final bool isLoading;
  final bool obscurePassword;

  const LoginFormState({this.isLoading = false, this.obscurePassword = true});

  LoginFormState copyWith({bool? isLoading, bool? obscurePassword}) {
    return LoginFormState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(const LoginFormState());

  void setLoading(bool value) => state = state.copyWith(isLoading: value);
  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
}

final loginFormProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>(
      (ref) => LoginFormNotifier(),
    );

class SignupFormState {
  final bool isLoading;
  final bool obscurePassword;
  final double passwordStrength;
  final String selectedRole;

  const SignupFormState({
    this.isLoading = false,
    this.obscurePassword = true,
    this.passwordStrength = 0.0,
    this.selectedRole = 'user',
  });

  SignupFormState copyWith({
    bool? isLoading,
    bool? obscurePassword,
    double? passwordStrength,
    String? selectedRole,
  }) {
    return SignupFormState(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      passwordStrength: passwordStrength ?? this.passwordStrength,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class SignupFormNotifier extends StateNotifier<SignupFormState> {
  SignupFormNotifier() : super(const SignupFormState());

  void setLoading(bool value) => state = state.copyWith(isLoading: value);
  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
  void updateStrength(double strength) =>
      state = state.copyWith(passwordStrength: strength.clamp(0.0, 1.0));
  void updateRole(String role) => state = state.copyWith(selectedRole: role);
}

final signupFormProvider =
    StateNotifierProvider<SignupFormNotifier, SignupFormState>(
      (ref) => SignupFormNotifier(),
    );
