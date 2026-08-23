# openapi.api.BitacoraApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bitacoraHealthBitacoraHealthGet**](BitacoraApi.md#bitacorahealthbitacorahealthget) | **GET** /bitacora/health | Bitacora Health


# **bitacoraHealthBitacoraHealthGet**
> BuiltMap<String, String> bitacoraHealthBitacoraHealthGet()

Bitacora Health

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getBitacoraApi();

try {
    final response = api.bitacoraHealthBitacoraHealthGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling BitacoraApi->bitacoraHealthBitacoraHealthGet: $e\n');
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

