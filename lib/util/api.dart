import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:intl/intl.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/key.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:kcs_engineer/util/navigationService.dart';
import 'package:package_info_plus/package_info_plus.dart';

final storage = new FlutterSecureStorage();

class ApiInterceptor implements InterceptorContract {
  String baseUrl = dotenv.env["API_BASE_URL"] ?? "";

  @override
  Future<RequestData> interceptRequest({required RequestData data}) async {
    try {
      var epoch = await storage.read(key: TOKEN_EXPIRY);

      if (epoch != null) {
        num tokenExpiry = num.parse(epoch.toString());
        var now = DateTime.now().toUtc().millisecondsSinceEpoch;
        if (tokenExpiry < now) {
          try {
            await renewAccessToken();
          } catch (err) {
            Helpers.isAuthenticated = false;
            await storage.delete(key: TOKEN);
            await storage.delete(key: TOKEN_EXPIRY);
            await storage.delete(key: REFRESH_TOKEN);
            await storage.delete(key: USERID);
            await NavigationService.pushReplacementNamed('signIn');
          }
        }
      }
      data.headers['Content-Type'] = 'application/json';
      data.headers['Accept'] = 'application/json';
      var token = await storage.read(key: TOKEN);
      String bearerAuth = 'Bearer $token';
      data.headers['Authorization'] = bearerAuth;
      print("#HEADERS: ${bearerAuth}");
    } catch (e) {
      print('Api Interceptor error $e');
    }
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({required ResponseData data}) async {
    var body = jsonDecode(data.body ?? "");

    if (data.statusCode == 401) {
      Helpers.isAuthenticated = false;
      await storage.delete(key: TOKEN);
      await storage.delete(key: TOKEN_EXPIRY);
      await storage.delete(key: REFRESH_TOKEN);
      await storage.delete(key: USERID);

      if (!(data.url?.contains('/login') ?? true)) {
        await NavigationService.pushReplacementNamed('signIn');
      }
    }

    return data;
  }

  static Future<void> renewAccessToken() async {
    var res = await Repositories.renewAccessToken();

    if (res.toString().toLowerCase() == "unauthenticated") {
      await NavigationService.pushReplacementNamed('signIn');
    }
  }
}

class Api {
  // static http.Client authClient =
  //     InterceptedClient.build(interceptors: [AuthInterceptor()]);
  static http.Client client =
      InterceptedClient.build(interceptors: [ApiInterceptor()]);

  static bearerGet(endpoint, {params}) async {
    try {
      final response;
      String baseUrl = dotenv.env["API_BASE_URL"] ?? "";

      String url = '$baseUrl/$endpoint';

      print("Url: $url");

      if (params != null) {
        response =
            await client.get(Uri.parse(url).replace(queryParameters: params));
      } else {
        response = await client.get(url.toUri());
      }

      print('Bearer Response: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('Get error : $e');
      return {'error': e.toString()};
    }
  }

  static bearerPatch(endpoint, {params, queryParams}) async {
    try {
      final response;
      String baseUrl = dotenv.env["API_BASE_URL"] ?? "";
      String url = '$baseUrl/$endpoint';

      print("bearerPatch Url: $url");
      if (params != null) {
        response = await client.patch(url.toUri(), body: params);
      } else {
        response = await client.patch(url.toUri());
      }
      print('Bearer Response: ${response.body}');
      try {
        json.decode(response.body) as Map<String, dynamic>;

        return json.decode(response.body);
      } on FormatException catch (e) {
        return response.body;
      }
    } catch (e) {
      print('Post error : $e');
      return {'error': e.toString()};
    }
  }

  static bearerDelete(endpoint, {params, queryParams}) async {
    try {
      final response;
      String baseUrl = dotenv.env["API_BASE_URL"] ?? "";

      String url = '$baseUrl/$endpoint';

      print("bearerPatch Url: $url");
      if (params != null) {
        response = await client.delete(url.toUri(), body: params);
      } else {
        response = await client.delete(url.toUri());
      }
      print('Bearer Response: ${response.body}');
      try {
        json.decode(response.body) as Map<String, dynamic>;

        return json.decode(response.body);
      } on FormatException catch (e) {
        return response.body;
      }
    } catch (e) {
      print('Post error : $e');
      return {'error': e.toString()};
    }
  }

  static bearerPost(endpoint, {params, queryParams}) async {
    try {
      final response;
      String baseUrl = dotenv.env["API_BASE_URL"] ?? "";

      String url = '$baseUrl/$endpoint';

      if (queryParams != null) {
        List<String> listParams = [];
        int cnt = 0;
        queryParams.forEach((key, val) {
          if (cnt == 0) {
            cnt++;
            listParams.add('?$key=$val');
            return;
          }
          listParams.add('&$key=$val');
          cnt++;
        });

        if (listParams.length > 0) {
          // print('#LISTPARAMS: ${listParams.join()}');
          url = '$url${listParams.join()}';
        }
      }
      var ll = json.encode(params);
      var req = client;
      print("bearerPost Url: $url");
      if (params != null) {
        response = await client.post(url.toUri(), body: json.encode(params));
      } else {
        response = await client.post(url.toUri());
      }
      print('Bearer Response: ${response.body}');
      try {
        json.decode(response.body) as Map<String, dynamic>;

        return json.decode(response.body);
      } on FormatException catch (e) {
        return response.body;
        // return {'success': false};
        // print('The provided string is not valid JSON');
      }
    } catch (e) {
      print('Post error : $e');
      return {'error': e.toString()};
    }
  }
}
