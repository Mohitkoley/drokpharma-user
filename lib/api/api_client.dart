import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/common/models/error_response.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  final SharedPreferences sharedPreferences;
  static final String noInternetMessage = 'connection_to_api_server_failed'.tr;
  final int timeoutInSeconds = 40;

  String? token;
  late Map<String, String> _mainHeaders;

  ApiClient({required this.appBaseUrl, required this.sharedPreferences}) {
    token = sharedPreferences.getString(AppConstants.token);
    if (kDebugMode) {
      print('Token: $token');
    }
    AddressModel? addressModel;
    try {
      addressModel = AddressModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!));
    }catch(_) {}
    int? moduleID;
    if(GetPlatform.isWeb && sharedPreferences.containsKey(AppConstants.moduleId)) {
      try {
        moduleID = ModuleModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.moduleId)!)).id;
      }catch(_) {}
    }
    updateHeader(
      token, addressModel?.zoneIds, addressModel?.areaIds,
      sharedPreferences.getString(AppConstants.languageCode), moduleID?.toString(), addressModel?.latitude,
      addressModel?.longitude, null,
    );
  }

  Map<String, String> updateHeader(String? token, List<int>? zoneIDs, List<int>? operationIds, String? languageCode, String? moduleID, String? latitude, String? longitude, int? zoneId, {bool setHeader = true, fromModule = false}) {
    Map<String, String> header = {};

    if(moduleID != null || sharedPreferences.getString(AppConstants.cacheModuleId) != null) {
      header.addAll({AppConstants.moduleId: '${moduleID ?? ModuleModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.cacheModuleId)!)).id}'});
    }
    header.addAll({
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.zoneId: (zoneId != null && fromModule) ? '$zoneId' : zoneIDs != null ? jsonEncode(zoneIDs) : '',
      ///this will add in ride module
      // AppConstants.operationAreaId: operationIds != null ? jsonEncode(operationIds) : '',
      AppConstants.localizationKey: languageCode ?? AppConstants.languages[0].languageCode!,
      AppConstants.latitude: latitude != null ? jsonEncode(latitude) : '',
      AppConstants.longitude: longitude != null ? jsonEncode(longitude) : '',
      'Authorization': 'Bearer $token'
    });
    if(setHeader) {
      _mainHeaders = header;
    }
    return header;
  }

  Map<String, String> getHeader() => _mainHeaders;

  static int _requestId = 0;

  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    final id = ++_requestId;
    final fullUrl = appBaseUrl + uri;
    final reqHeaders = headers ?? _mainHeaders;
    final stopwatch = Stopwatch()..start();
    _logRequest(id: id, method: 'GET', url: fullUrl, headers: reqHeaders);

    try {
      http.Response response = await http.get(
        Uri.parse(fullUrl),
        headers: reqHeaders,
      ).timeout(Duration(seconds: timeoutInSeconds));
      stopwatch.stop();

      _logResponse(
        id: id,
        method: 'GET',
        url: fullUrl,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
        body: response.body,
        elapsedMs: stopwatch.elapsedMilliseconds,
        headers: response.headers,
      );

      return handleResponse(response, uri, handleError);
    } catch (e, stack) {
      stopwatch.stop();
      _logException(id: id, method: 'GET', url: fullUrl, error: e, stackTrace: stack, elapsedMs: stopwatch.elapsedMilliseconds);
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postData(String uri, dynamic body, {Map<String, String>? headers, int? timeout, bool handleError = true}) async {
    final id = ++_requestId;
    final fullUrl = appBaseUrl + uri;
    final reqHeaders = headers ?? _mainHeaders;
    final stopwatch = Stopwatch()..start();

    _logRequest(id: id, method: 'POST', url: fullUrl, headers: reqHeaders, body: body);

    try {
      dynamic encodedBody;
      if (body is Map) {
        Map<dynamic, dynamic> newBody = {};
        body.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            newBody.addAll({key: value});
          }
        });
        encodedBody = jsonEncode(newBody);
      } else if (body != null) {
        encodedBody = jsonEncode(body);
      }

      http.Response response = await http.post(
        Uri.parse(fullUrl),
        body: encodedBody,
        headers: reqHeaders,
      ).timeout(Duration(seconds: timeout ?? timeoutInSeconds));
      stopwatch.stop();

      _logResponse(
        id: id,
        method: 'POST',
        url: fullUrl,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
        body: response.body,
        elapsedMs: stopwatch.elapsedMilliseconds,
        headers: response.headers,
      );

      return handleResponse(response, uri, handleError);
    } catch (e, stack) {
      stopwatch.stop();
      _logException(id: id, method: 'POST', url: fullUrl, error: e, stackTrace: stack, elapsedMs: stopwatch.elapsedMilliseconds);
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> postMultipartData(String uri, Map<String, String> body, List<MultipartBody> multipartBody, {List<MultipartDocument>? multipartDoc, Map<String, String>? headers, bool handleError = true}) async {
    final id = ++_requestId;
    final fullUrl = appBaseUrl + uri;
    final reqHeaders = headers ?? _mainHeaders;
    final stopwatch = Stopwatch()..start();

    _logRequest(
      id: id,
      method: 'POST (MULTIPART)',
      url: fullUrl,
      headers: reqHeaders,
      body: body,
      multipartBody: multipartBody,
      multipartDoc: multipartDoc,
    );

    try {
      http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse(fullUrl));
      request.headers.addAll(reqHeaders);
      for(MultipartBody multipart in multipartBody) {
        if(multipart.file != null) {
          if(kIsWeb) {
            Uint8List bytes = await multipart.file!.readAsBytes();
            http.MultipartFile part = http.MultipartFile.fromBytes(
              multipart.key,
              bytes,
              filename: 'image.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(part);
          } else {
            File file = File(multipart.file!.path);
            request.files.add(http.MultipartFile(
              multipart.key, file.readAsBytes().asStream(), file.lengthSync(), filename: file.path.split('/').last,
            ));
          }
        }
      }

      if(multipartDoc != null && multipartDoc.isNotEmpty){
        for(MultipartDocument file in multipartDoc){
          if(kIsWeb) {
            PlatformFile platformFile = file.file!.files.first;
            request.files.add(
              http.MultipartFile.fromBytes(
                file.key,
                platformFile.bytes!,
                filename: platformFile.name,
              ),
            );
          } else {
            File other = File(file.file!.files.single.path!);
            Uint8List list0 = await other.readAsBytes();
            var part = http.MultipartFile(file.key, other.readAsBytes().asStream(), list0.length, filename: basename(other.path));
            request.files.add(part);
          }
        }
      }

      request.fields.addAll(body);
      http.Response response = await http.Response.fromStream(await request.send());
      stopwatch.stop();

      _logResponse(
        id: id,
        method: 'POST (MULTIPART)',
        url: fullUrl,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
        body: response.body,
        elapsedMs: stopwatch.elapsedMilliseconds,
        headers: response.headers,
      );

      return handleResponse(response, uri, handleError);
    } catch (e, stack) {
      stopwatch.stop();
      _logException(id: id, method: 'POST (MULTIPART)', url: fullUrl, error: e, stackTrace: stack, elapsedMs: stopwatch.elapsedMilliseconds);
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> putData(String uri, dynamic body, {Map<String, String>? headers, bool handleError = true}) async {
    final id = ++_requestId;
    final fullUrl = appBaseUrl + uri;
    final reqHeaders = headers ?? _mainHeaders;
    final stopwatch = Stopwatch()..start();

    _logRequest(id: id, method: 'PUT', url: fullUrl, headers: reqHeaders, body: body);

    try {
      http.Response response = await http.put(
        Uri.parse(fullUrl),
        body: jsonEncode(body),
        headers: reqHeaders,
      ).timeout(Duration(seconds: timeoutInSeconds));
      stopwatch.stop();

      _logResponse(
        id: id,
        method: 'PUT',
        url: fullUrl,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
        body: response.body,
        elapsedMs: stopwatch.elapsedMilliseconds,
        headers: response.headers,
      );

      return handleResponse(response, uri, handleError);
    } catch (e, stack) {
      stopwatch.stop();
      _logException(id: id, method: 'PUT', url: fullUrl, error: e, stackTrace: stack, elapsedMs: stopwatch.elapsedMilliseconds);
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Future<Response> deleteData(String uri, {Map<String, String>? headers, bool handleError = true}) async {
    final id = ++_requestId;
    final fullUrl = appBaseUrl + uri;
    final reqHeaders = headers ?? _mainHeaders;
    final stopwatch = Stopwatch()..start();

    _logRequest(id: id, method: 'DELETE', url: fullUrl, headers: reqHeaders);

    try {
      http.Response response = await http.delete(
        Uri.parse(fullUrl),
        headers: reqHeaders,
      ).timeout(Duration(seconds: timeoutInSeconds));
      stopwatch.stop();

      _logResponse(
        id: id,
        method: 'DELETE',
        url: fullUrl,
        statusCode: response.statusCode,
        reasonPhrase: response.reasonPhrase,
        body: response.body,
        elapsedMs: stopwatch.elapsedMilliseconds,
        headers: response.headers,
      );

      return handleResponse(response, uri, handleError);
    } catch (e, stack) {
      stopwatch.stop();
      _logException(id: id, method: 'DELETE', url: fullUrl, error: e, stackTrace: stack, elapsedMs: stopwatch.elapsedMilliseconds);
      return Response(statusCode: 1, statusText: noInternetMessage);
    }
  }

  Response handleResponse(http.Response response, String uri, bool handleError) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {}

    Response response0 = Response(
      body: body ?? response.body,
      bodyString: response.body.toString(),
      request: Request(headers: response.request!.headers, method: response.request!.method, url: response.request!.url),
      headers: response.headers,
      statusCode: response.statusCode,
      statusText: response.reasonPhrase,
    );

    if (response0.statusCode != 200 && response0.body != null && response0.body is! String) {
      if (response0.body.toString().startsWith('{errors: [{code:')) {
        ErrorResponse errorResponse = ErrorResponse.fromJson(response0.body);
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: errorResponse.errors![0].message);
      } else if (response0.body.toString().startsWith('{response_code: zone_404, message:')) {
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: response0.body['message']);
      } else if (response0.body.toString().startsWith('{message')) {
        response0 = Response(statusCode: response0.statusCode, body: response0.body, statusText: response0.body['message']);
      }
    } else if (response0.statusCode != 200 && response0.body == null) {
      response0 = Response(statusCode: 0, statusText: noInternetMessage);
    }

    if (handleError) {
      if (response0.statusCode == 200) {
        return response0;
      } else {
        ApiChecker.checkApi(response0);
        return const Response();
      }
    } else {
      return response0;
    }
  }

  static void _logRequest({
    required int id,
    required String method,
    required String url,
    required Map<String, String> headers,
    dynamic body,
    List<MultipartBody>? multipartBody,
    List<MultipartDocument>? multipartDoc,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln('\n┌─── 🚀 [API REQUEST #$id] ──────────────────────────────────────────');
    buffer.writeln('│ Method  : $method');
    buffer.writeln('│ URL     : $url');
    buffer.writeln('│ Time    : ${DateTime.now().toIso8601String()}');
    buffer.writeln('│ Headers : ${_formatHeaders(headers)}');
    if (body != null) {
      buffer.writeln('│ Body    :\n${_indent(_prettyJson(body))}');
    }
    if (multipartBody != null && multipartBody.isNotEmpty) {
      buffer.writeln('│ Files   : ${multipartBody.map((e) => '${e.key}=${e.file?.name ?? e.file?.path}').join(', ')}');
    }
    if (multipartDoc != null && multipartDoc.isNotEmpty) {
      buffer.writeln('│ Docs    : ${multipartDoc.map((e) => '${e.key}=${e.file?.files.first.name}').join(', ')}');
    }
    buffer.write('└──────────────────────────────────────────────────────────────────');
    _printWrapped(buffer.toString());
  }

  static void _logResponse({
    required int id,
    required String method,
    required String url,
    required int statusCode,
    required String? reasonPhrase,
    required dynamic body,
    required int elapsedMs,
    required Map<String, String> headers,
  }) {
    if (!kDebugMode) return;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';
    final buffer = StringBuffer();
    buffer.writeln('\n┌─── $icon [API RESPONSE #$id] ─────────────────────────────────────────');
    buffer.writeln('│ $method: $url');
    buffer.writeln('│ Status  : $statusCode ${reasonPhrase ?? ''} (took ${elapsedMs}ms)');
    if (!isSuccess) {
      _extractAndFormatErrors(body, buffer);
    }
    buffer.writeln('│ Response Body:\n${_indent(_prettyJson(body))}');
    buffer.write('└──────────────────────────────────────────────────────────────────');
    _printWrapped(buffer.toString());
  }

  static void _logException({
    required int id,
    required String method,
    required String url,
    required Object error,
    StackTrace? stackTrace,
    int? elapsedMs,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln('\n┌─── 🚨 [API EXCEPTION #$id] ─────────────────────────────────────────');
    buffer.writeln('│ $method: $url');
    if (elapsedMs != null) buffer.writeln('│ Duration: ${elapsedMs}ms');
    buffer.writeln('│ Error   : $error');
    if (stackTrace != null) {
      buffer.writeln('│ StackTrace:');
      final lines = stackTrace.toString().split('\n').where((l) => l.trim().isNotEmpty).take(5);
      for (final line in lines) {
        buffer.writeln('│   $line');
      }
    }
    buffer.write('└──────────────────────────────────────────────────────────────────');
    _printWrapped(buffer.toString());
  }

  static void _extractAndFormatErrors(dynamic body, StringBuffer buffer) {
    try {
      dynamic parsed = body;
      if (body is String) {
        try {
          parsed = jsonDecode(body);
        } catch (_) {}
      }
      if (parsed is Map && parsed.containsKey('errors') && parsed['errors'] is List) {
        buffer.writeln('│ Errors Breakdown:');
        for (var err in parsed['errors']) {
          buffer.writeln('│   • [${err['code'] ?? 'field'}]: ${err['message'] ?? err}');
        }
      } else if (parsed is Map && parsed.containsKey('message')) {
        buffer.writeln('│ Message : ${parsed['message']}');
      }
    } catch (_) {}
  }

  static String _formatHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return '{}';
    final buffer = StringBuffer('{\n');
    headers.forEach((key, value) {
      final displayValue = (key.toLowerCase() == 'authorization' && value.length > 30)
          ? '${value.substring(0, 25)}...'
          : value;
      buffer.writeln('│   $key: $displayValue');
    });
    buffer.write('│ }');
    return buffer.toString();
  }

  static String _prettyJson(dynamic json) {
    if (json == null) return 'null';
    try {
      if (json is String) {
        try {
          final decoded = jsonDecode(json);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return json;
        }
      }
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  static String _indent(String text) {
    return text.split('\n').map((line) => '│   $line').join('\n');
  }

  static void _printWrapped(String text) {
    final pattern = RegExp('.{1,800}');
    for (final line in text.split('\n')) {
      if (line.length <= 800) {
        debugPrint(line);
      } else {
        pattern.allMatches(line).forEach((match) => debugPrint(match.group(0)));
      }
    }
  }
}

class MultipartBody {
  String key;
  XFile? file;

  MultipartBody(this.key, this.file);
}

class MultipartDocument {
  String key;
  FilePickerResult? file;
  MultipartDocument(this.key, this.file);
}