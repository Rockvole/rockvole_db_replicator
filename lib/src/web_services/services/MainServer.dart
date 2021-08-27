import 'dart:io';

import 'package:rockvole_db/rockvole_db.dart';
import 'package:rockvole_db/rockvole_transactions.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

final HOST = "127.0.0.1"; // eg: localhost
final DATA_FILE = "data.json";

void start(SchemaMetaData smd) {
  ConfigurationNameDefaults defaults = ConfigurationNameDefaults();
  HttpServer.bind(HOST, UrlTools.C_SERVER_PORT).then((server) {
    server.listen((HttpRequest request) {
      switch (request.method) {
        case "GET":
          handleGet(request, smd, defaults);
          break;
        case "POST":
          handlePost(request, smd, defaults);
          break;
        case "OPTIONS":
          handleOptions(request, smd);
          break;
        default:
          defaultHandler(request);
      }
    }, onError: printError);

    print("Listening for GET and POST on http://$HOST:" +
        UrlTools.C_SERVER_PORT.toString());
  }, onError: printError);
}

/**
 * Handle GET requests by reading the contents of data.json
 * and returning it to the client
 */
Future<void> handleGet(HttpRequest req, SchemaMetaData smd,
    ConfigurationNameDefaults defaults) async {
  HttpResponse res = req.response;
  print("${req.method}: ${req.uri.toString()}");
  String? json;
  addCorsHeaders(res);
  Map<String, String> parameters = req.uri.queryParameters;

  if (req.uri.path == UrlTools.C_REST_BASE_URL + UrlTools.C_LATEST_ROWS_URL) {
    print("FOUND GetLatestRows");
    GetLatestRows getLatestRows = GetLatestRows(smd, defaults);
    await getLatestRows.init();
    int? userId = parseInt(parameters,'user_id');
    int? waterLineTs = parseInt(parameters,'water_line');
    int? limit = parseInt(parameters,'limit');
    String? signature = parameters['sig'];
    int? ts = parseInt(parameters,'ts');
    String? testPassword = parameters['test_pass'];
    String? database = parameters['database'];
    json = await getLatestRows.getJsonEntries(userId, waterLineTs,
        limit, signature, ts, testPassword, database);
  } else if (req.uri.path ==
      UrlTools.C_REST_BASE_URL + UrlTools.C_AUTHENTICATE_URL) {
    print("FOUND GetAuthentication");
    GetAuthentication getAuthentication = GetAuthentication(smd);
    await getAuthentication.init();
    int? userId = parseInt(parameters,'user_id');
    String? email = parameters['email'];
    int? waterLineTs = parseInt(parameters,'water_line');
    int? stateInt = parseInt(parameters,'state');
    int? crc = parseInt(parameters,'crc');
    String? signature = parameters['sig'];
    int? ts = parseInt(parameters,'ts');
    int? version = parseInt(parameters,'version');
    String? testPassword = parameters['test_pass'];
    String? database = parameters['database'];
    json = await getAuthentication.getJsonEntries(userId, email, waterLineTs,
        crc, signature, ts, version, testPassword, database);
  } else if (req.uri.path ==
      UrlTools.C_REST_BASE_URL + UrlTools.C_LATEST_FIELDS_URL) {
    print("FOUND GetLatestWaterLineFields");
    GetLatestWaterLineFields getLatestWaterLineFields =
        GetLatestWaterLineFields(smd, defaults);
    await getLatestWaterLineFields.init();
    int? userId = parseInt(parameters,'user_id');
    int? remoteTs = parseInt(parameters,'remote_ts');
    int? changeSuperTypeInt = parseInt(parameters,'change_super_type');
    int? limit = parseInt(parameters,'limit');
    String? signature = parameters['sig'];
    int? ts = parseInt(parameters,'ts');
    String? testPassword = parameters['test_pass'];
    String? database = parameters['database'];
    json = await getLatestWaterLineFields.getJsonEntries(userId, remoteTs,
        changeSuperTypeInt, limit, signature, ts, testPassword, database);
  }
  if (json != null) {
    res.headers.add(HttpHeaders.contentTypeHeader, "application/json");
    res.write(json);
  }
  await res.close();
}

/**
 * Handle POST requests by overwriting the contents of data.json
 * Return the same set of data back to the client.
 */
Future<void> handlePost(HttpRequest req, SchemaMetaData smd,
    ConfigurationNameDefaults defaults) async {
  HttpResponse res = req.response;
  print("${req.method}: ${req.uri.path}");
  String? json;
  addCorsHeaders(res);
  Map<String, String> parameters = req.uri.queryParameters;

  if (req.uri.path == UrlTools.C_REST_BASE_URL + UrlTools.C_NEW_ROW_POST_URL) {
    print("FOUND PostNewRow");
    PostNewRow postNewRow = PostNewRow(smd, defaults);
    await postNewRow.init();
    int userId = int.parse(parameters['user_id']!);
    int ts = int.parse(parameters['ts']!);
    int version = int.parse(parameters['version']!);
    String? testPassword = parameters['test_pass'];
    String? database = parameters['database'];
    String signature = parameters['sig']!;
    String? jsonString;
    await for (List<int> data in req) {
      jsonString = String.fromCharCodes(data);
    }
    json = await postNewRow.putEntry(
        userId, ts, version, testPassword, database, signature, jsonString);
  } else if (req.uri.path ==
      UrlTools.C_REST_BASE_URL + UrlTools.C_WATERLINE_FIELDS_POST_URL) {
    print("FOUND PostWaterLineFields");
    PostWaterLineFields postWaterLineFields =
        PostWaterLineFields(smd, defaults);
    await postWaterLineFields.init();
    int userId = int.parse(parameters['user_id']!);
    int ts = int.parse(parameters['ts']!);
    String testPassword = parameters['test_pass']!;
    String database = parameters['database']!;
    String signature = parameters['sig']!;
    String? jsonString;
    await for (List<int> data in req) {
      jsonString = String.fromCharCodes(data);
    }
    json = await postWaterLineFields.putEntry(
        userId, ts, testPassword, database, signature, jsonString);
  } else if (req.uri.path ==
      UrlTools.C_REST_BASE_URL + UrlTools.C_SELECTED_ROWS_POST_URL) {
    print("FOUND RequestSelectedRows");
    RequestSelectedRows requestSelectedRows =
        RequestSelectedRows(smd, defaults);
    await requestSelectedRows.init();
    int userId = int.parse(parameters['user_id']!);
    int ts = int.parse(parameters['ts']!);
    int version = int.parse(parameters['version']!);
    String testPassword = parameters['test_pass']!;
    String database = parameters['database']!;
    String signature = parameters['sig']!;
    String? jsonString;
    await for (List<int> data in req) {
      jsonString = String.fromCharCodes(data);
    }
    json = await requestSelectedRows.putEntry(
        userId, ts, version, testPassword, database, signature, jsonString);
  }
  if (json != null) {
    res.headers.add(HttpHeaders.contentTypeHeader, "application/json");
    res.write(json);
  }
  await res.close();
}

/**
 * Add Cross-site headers to enable accessing this server from pages
 * not served by this server
 *
 * See: http://www.html5rocks.com/en/tutorials/cors/
 * and http://enable-cors.org/server.html
 */
void addCorsHeaders(HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers",
      "Origin, X-Requested-With, Content-Type, Accept");
}

void handleOptions(HttpRequest req, SchemaMetaData smd) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  print("${req.method}: ${req.uri.path}");
  res.statusCode = HttpStatus.NO_CONTENT;
  res.close();
}

void defaultHandler(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  res.statusCode = HttpStatus.NOT_FOUND;
  res.write("Not found: ${req.method}, ${req.uri.path}");
  res.close();
}

void printError(error) => print(error);

int? parseInt(Map<String, String> parameters, String key) {
  if(parameters.containsKey(key)) return int.parse(parameters[key]!);
  return null;
}
