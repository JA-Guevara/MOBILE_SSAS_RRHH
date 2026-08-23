# openapi.api.AuthApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authHealthAuthHealthGet**](AuthApi.md#authhealthauthhealthget) | **GET** /auth/health | Auth Health
[**currentUserAuthMeGet**](AuthApi.md#currentuserauthmeget) | **GET** /auth/me | Current User
[**forgotPasswordAuthPasswordForgotPost**](AuthApi.md#forgotpasswordauthpasswordforgotpost) | **POST** /auth/password/forgot | Forgot Password
[**loginUserAuthLoginPost**](AuthApi.md#loginuserauthloginpost) | **POST** /auth/login | Login User
[**logoutUserAuthLogoutPost**](AuthApi.md#logoutuserauthlogoutpost) | **POST** /auth/logout | Logout User
[**refreshTokenAuthRefreshPost**](AuthApi.md#refreshtokenauthrefreshpost) | **POST** /auth/refresh | Refresh Token
[**registerUserAuthRegisterPost**](AuthApi.md#registeruserauthregisterpost) | **POST** /auth/register | Register User
[**resetPasswordAuthPasswordResetPost**](AuthApi.md#resetpasswordauthpasswordresetpost) | **POST** /auth/password/reset | Reset Password


# **authHealthAuthHealthGet**
> BuiltMap<String, String> authHealthAuthHealthGet()

Auth Health

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();

try {
    final response = api.authHealthAuthHealthGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->authHealthAuthHealthGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**BuiltMap&lt;String, String&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **currentUserAuthMeGet**
> UserSchema currentUserAuthMeGet()

Current User

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();

try {
    final response = api.currentUserAuthMeGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->currentUserAuthMeGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserSchema**](UserSchema.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **forgotPasswordAuthPasswordForgotPost**
> ForgotPasswordResponseSchema forgotPasswordAuthPasswordForgotPost(forgotPasswordSchema)

Forgot Password

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();
final ForgotPasswordSchema forgotPasswordSchema = ; // ForgotPasswordSchema | 

try {
    final response = api.forgotPasswordAuthPasswordForgotPost(forgotPasswordSchema);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->forgotPasswordAuthPasswordForgotPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **forgotPasswordSchema** | [**ForgotPasswordSchema**](ForgotPasswordSchema.md)|  | 

### Return type

[**ForgotPasswordResponseSchema**](ForgotPasswordResponseSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **loginUserAuthLoginPost**
> TokenPairSchema loginUserAuthLoginPost(loginSchema)

Login User

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();
final LoginSchema loginSchema = ; // LoginSchema | 

try {
    final response = api.loginUserAuthLoginPost(loginSchema);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->loginUserAuthLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginSchema** | [**LoginSchema**](LoginSchema.md)|  | 

### Return type

[**TokenPairSchema**](TokenPairSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **logoutUserAuthLogoutPost**
> MessageSchema logoutUserAuthLogoutPost(refreshTokenSchema)

Logout User

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();
final RefreshTokenSchema refreshTokenSchema = ; // RefreshTokenSchema | 

try {
    final response = api.logoutUserAuthLogoutPost(refreshTokenSchema);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->logoutUserAuthLogoutPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshTokenSchema** | [**RefreshTokenSchema**](RefreshTokenSchema.md)|  | 

### Return type

[**MessageSchema**](MessageSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshTokenAuthRefreshPost**
> TokenPairSchema refreshTokenAuthRefreshPost(refreshTokenSchema)

Refresh Token

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();
final RefreshTokenSchema refreshTokenSchema = ; // RefreshTokenSchema | 

try {
    final response = api.refreshTokenAuthRefreshPost(refreshTokenSchema);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->refreshTokenAuthRefreshPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshTokenSchema** | [**RefreshTokenSchema**](RefreshTokenSchema.md)|  | 

### Return type

[**TokenPairSchema**](TokenPairSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerUserAuthRegisterPost**
> UserSchema registerUserAuthRegisterPost(registerSchema)

Register User

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();
final RegisterSchema registerSchema = ; // RegisterSchema | 

try {
    final response = api.registerUserAuthRegisterPost(registerSchema);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->registerUserAuthRegisterPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerSchema** | [**RegisterSchema**](RegisterSchema.md)|  | 

### Return type

[**UserSchema**](UserSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resetPasswordAuthPasswordResetPost**
> MessageSchema resetPasswordAuthPasswordResetPost(resetPasswordSchema)

Reset Password

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();
final ResetPasswordSchema resetPasswordSchema = ; // ResetPasswordSchema | 

try {
    final response = api.resetPasswordAuthPasswordResetPost(resetPasswordSchema);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->resetPasswordAuthPasswordResetPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resetPasswordSchema** | [**ResetPasswordSchema**](ResetPasswordSchema.md)|  | 

### Return type

[**MessageSchema**](MessageSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

