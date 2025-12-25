/// Models for authentication requests to the backend

class LoginRequest {
  final String usernameOrEmail;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.usernameOrEmail,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'usernameOrEmail': usernameOrEmail,
      'password': password,
      'rememberMe': rememberMe,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}

class VerifyRegistrationRequest {
  final String email;
  final String otp;

  VerifyRegistrationRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    final emailTrimmed = email.trim().toLowerCase();
    final otpTrimmed = otp.trim();
    print(
        '[VerifyRegistrationRequest] email: $emailTrimmed, otpCode: $otpTrimmed');
    return {
      'email': emailTrimmed,
      'otpCode': otpTrimmed, // Backend expects 'otpCode' field
    };
  }
}

class SendOtpRequest {
  final String email;

  SendOtpRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
