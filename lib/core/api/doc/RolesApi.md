# openapi.api.RolesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignPermissionsRolesRoleIdPermissionsPut**](RolesApi.md#assignpermissionsrolesroleidpermissionsput) | **PUT** /roles/{role_id}/permissions | Assign Permissions
[**createRoleRolesPost**](RolesApi.md#createrolerolespost) | **POST** /roles | Create Role
[**deleteRoleRolesRoleIdDelete**](RolesApi.md#deleterolerolesroleiddelete) | **DELETE** /roles/{role_id} | Delete Role
[**getRoleRolesRoleIdGet**](RolesApi.md#getrolerolesroleidget) | **GET** /roles/{role_id} | Get Role
[**listRolesRolesGet**](RolesApi.md#listrolesrolesget) | **GET** /roles | List Roles
[**updateRoleRolesRoleIdPatch**](RolesApi.md#updaterolerolesroleidpatch) | **PATCH** /roles/{role_id} | Update Role


# **assignPermissionsRolesRoleIdPermissionsPut**
> RoleSchema assignPermissionsRolesRoleIdPermissionsPut(roleId, assignPermissionsRequest)

Assign Permissions

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getRolesApi();
final String roleId = roleId_example; // String | 
final AssignPermissionsRequest assignPermissionsRequest = ; // AssignPermissionsRequest | 

try {
    final response = api.assignPermissionsRolesRoleIdPermissionsPut(roleId, assignPermissionsRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RolesApi->assignPermissionsRolesRoleIdPermissionsPut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roleId** | **String**|  | 
 **assignPermissionsRequest** | [**AssignPermissionsRequest**](AssignPermissionsRequest.md)|  | 

### Return type

[**RoleSchema**](RoleSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createRoleRolesPost**
> RoleSchema createRoleRolesPost(createRoleRequest)

Create Role

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getRolesApi();
final CreateRoleRequest createRoleRequest = ; // CreateRoleRequest | 

try {
    final response = api.createRoleRolesPost(createRoleRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RolesApi->createRoleRolesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createRoleRequest** | [**CreateRoleRequest**](CreateRoleRequest.md)|  | 

### Return type

[**RoleSchema**](RoleSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteRoleRolesRoleIdDelete**
> deleteRoleRolesRoleIdDelete(roleId)

Delete Role

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getRolesApi();
final String roleId = roleId_example; // String | 

try {
    api.deleteRoleRolesRoleIdDelete(roleId);
} on DioException catch (e) {
    print('Exception when calling RolesApi->deleteRoleRolesRoleIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roleId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRoleRolesRoleIdGet**
> RoleSchema getRoleRolesRoleIdGet(roleId)

Get Role

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getRolesApi();
final String roleId = roleId_example; // String | 

try {
    final response = api.getRoleRolesRoleIdGet(roleId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RolesApi->getRoleRolesRoleIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roleId** | **String**|  | 

### Return type

[**RoleSchema**](RoleSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRolesRolesGet**
> BuiltList<RoleSchema> listRolesRolesGet()

List Roles

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getRolesApi();

try {
    final response = api.listRolesRolesGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling RolesApi->listRolesRolesGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;RoleSchema&gt;**](RoleSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateRoleRolesRoleIdPatch**
> RoleSchema updateRoleRolesRoleIdPatch(roleId, updateRoleRequest)

Update Role

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getRolesApi();
final String roleId = roleId_example; // String | 
final UpdateRoleRequest updateRoleRequest = ; // UpdateRoleRequest | 

try {
    final response = api.updateRoleRolesRoleIdPatch(roleId, updateRoleRequest);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RolesApi->updateRoleRolesRoleIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roleId** | **String**|  | 
 **updateRoleRequest** | [**UpdateRoleRequest**](UpdateRoleRequest.md)|  | 

### Return type

[**RoleSchema**](RoleSchema.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

