import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:rockvole_db/rockvole_web_services.dart';

class Client {
  static final int C_TIMEOUT_CONNECTION = 3000;
  static final int C_TIMEOUT_SOCKET = 5000;
  String? host;
  int? port;
  String basePath;
  static late String url;
  int? statusCode;

  Client(this.host, this.port, this.basePath) {
    if (host == null) throw ArgumentError("'host' must not be null");
  }

  String get server => "http://" + host.toString() + ":" + port.toString() + basePath;

  int? getStatusCode() {
    return statusCode;
  }

  String getURLString() {
    return server + url;
  }

  http.Client getDefaultHttpClient() {
    http.Client client = http.Client();
    return client;
  }

  void processStatusCodes(int sc) {
    if (sc == 404)
      throw TransmitStatusException(TransmitStatus.RESOURCE_NOT_FOUND);
  }

  Future<String> getBaseURI(String path, String query) async {
    Client.url = query;
    String result;
    http.Client httpClient = getDefaultHttpClient();

    late http.Response response;
    late Uri uri;
    try {
      uri = Uri(
          host: host,
          scheme: 'http',
          path: basePath + path,
          query: query,
          port: port);
      print(uri);
    } on FormatException catch (e) {
      print("WS $e");
    }
    try {
      response = await httpClient.get(uri);
    } on SocketException catch (e) {
      print("WS $e");
      throw TransmitStatusException(TransmitStatus.SERVER_NOT_FOUND);
    }
    switch (response.statusCode) {
      case HttpStatus.ok:
        result = response.body;
        break;
      case HttpStatus.requestTimeout:
        throw TransmitStatusException(TransmitStatus.SOCKET_TIMEOUT);
      case HttpStatus.notFound:
        throw TransmitStatusException(TransmitStatus.SERVER_NOT_FOUND);
      default:
        throw TransmitStatusException(TransmitStatus.INVALID_SERVER_REQUEST);
    }
    httpClient.close();
    return result;
  }

  Future<String> getBaseURIText(String path, String query) async {
    Client.url = query;
    String result;
    http.Client httpClient = getDefaultHttpClient();

    late http.Response response;
    late Uri uri;
    try {
      uri = Uri(
          host: host,
          scheme: 'http',
          path: basePath + path,
          query: query,
          port: port);
      print(uri);
    } on FormatException catch (e) {
      print("WS $e");
    }
    try {
      response = await httpClient.get(uri);
    } on SocketException catch (e) {
      print("WS $e");
      throw TransmitStatusException(TransmitStatus.SERVER_NOT_FOUND);
    }
    switch (response.statusCode) {
      case HttpStatus.ok:
        result = response.body;
        break;
      case HttpStatus.requestTimeout:
        throw TransmitStatusException(TransmitStatus.SOCKET_TIMEOUT);
      case HttpStatus.notFound:
        throw TransmitStatusException(TransmitStatus.SERVER_NOT_FOUND);
      default:
        throw TransmitStatusException(TransmitStatus.INVALID_SERVER_REQUEST);
    }
    return result;
  }

  Future<String> postBaseURI(String str, String path, String query) async {
    Client.url = query;
    String result;
    http.Client httpClient = getDefaultHttpClient();

    late http.Response response;
    late Uri uri;
    try {
      uri = Uri(
          host: host,
          scheme: 'http',
          path: basePath + path,
          query: query,
          port: port);
      print(uri);
    } on FormatException catch (e) {
      print("WS $e");
    }
    try {
      response = await httpClient.post(uri, body: str);
    } on SocketException catch (e) {
      print("WS $e");
      throw TransmitStatusException(TransmitStatus.SERVER_NOT_FOUND);
    }
    switch (response.statusCode) {
      case HttpStatus.ok:
        result = response.body;
        break;
      case HttpStatus.requestTimeout:
        throw TransmitStatusException(TransmitStatus.SOCKET_TIMEOUT);
      case HttpStatus.notFound:
        throw TransmitStatusException(TransmitStatus.SERVER_NOT_FOUND);
      default:
        throw TransmitStatusException(TransmitStatus.INVALID_SERVER_REQUEST);
    }
    httpClient.close();
    return result;
  }

  @override
  String toString() {
    return server;
  }
}
