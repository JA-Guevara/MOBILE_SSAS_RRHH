import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for AuthApi
void main() {
  final instance = Openapi().getAuthApi();

  group(AuthApi, () {
    // Auth Health
    //
    //Future<BuiltMap<String, String>> authHealthAuthHealthGet() async
    test('test authHealthAuthHealthGet', () async {
      // TODO
    });

    // Current User
    //
    //Future<UserSchema> currentUserAuthMeGet() async
    test('test currentUserAuthMeGet', () async {
      // TODO
    });

    // Forgot Password
    //
    //Future<ForgotPasswordResponseSchema> forgotPasswordAuthPasswordForgotPost(ForgotPasswordSchema forgotPasswordSchema) async
    test('test forgotPasswordAuthPasswordForgotPost', () async {
      // TODO
    });

    // Login User
    //
    //Future<TokenPairSchema> loginUserAuthLoginPost(LoginSchema loginSchema) async
    test('test loginUserAuthLoginPost', () async {
      // TODO
    });

    // Logout User
    //
    //Future<MessageSchema> logoutUserAuthLogoutPost(RefreshTokenSchema refreshTokenSchema) async
    test('test logoutUserAuthLogoutPost', () async {
      // TODO
    });

    // Refresh Token
    //
    //Future<TokenPairSchema> refreshTokenAuthRefreshPost(RefreshTokenSchema refreshTokenSchema) async
    test('test refreshTokenAuthRefreshPost', () async {
      // TODO
    });

    // Register User
    //
    //Future<UserSchema> registerUserAuthRegisterPost(RegisterSchema registerSchema) async
    test('test registerUserAuthRegisterPost', () async {
      // TODO
    });

    // Reset Password
    //
    //Future<MessageSchema> resetPasswordAuthPasswordResetPost(ResetPasswordSchema resetPasswordSchema) async
    test('test resetPasswordAuthPasswordResetPost', () async {
      // TODO
    });

  });
}
