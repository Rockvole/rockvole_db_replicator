import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SignedRequestHelper2 {
  static final String REQUEST_METHOD = "GET";
  late String accessString;
  var hmacSha256;

  SignedRequestHelper2(String email, String secretKey) {
    if (secretKey == null) throw ArgumentError("SecretKey cannot be null");
    accessString = "email=" + percentEncodeRfc3986(email.toLowerCase()) + "&";
    var key = utf8.encode(secretKey);

    hmacSha256 = Hmac(sha256, key); // HMAC-SHA256
  }

  String sign(Map<String, String> params) {
    SplayTreeMap<String, String> sortedParamMap = SplayTreeMap.from(params);
    String canonicalQS = canonicalize(sortedParamMap);
    String toSign = REQUEST_METHOD + "\n" + accessString + canonicalQS;
    String hmacString = hmac(toSign);
    String sig = percentEncodeRfc3986(hmacString);
    String url = canonicalQS + "&sig=" + sig;
    return url;
  }

  String getHmac(Map<String, String> params) {
    SplayTreeMap<String, String> sortedParamMap = SplayTreeMap.from(params);
    String canonicalQS = canonicalize(sortedParamMap);
    String toSign = REQUEST_METHOD + "\n" + accessString + canonicalQS;

    String hmacString = hmac(toSign);
    String sig = percentEncodeRfc3986(hmacString);
    return sig;
  }

  String hmac(String stringToSign) {
    var bytes = utf8.encode(stringToSign);
    var digest = hmacSha256.convert(bytes);
    String base64Mac = base64.encode(digest.bytes);
    return base64Mac;
  }

  static String canonicalize(SplayTreeMap<String, String> sortedParamMap) {
    if (sortedParamMap.isEmpty) {
      return "";
    }
    StringBuffer buffer = StringBuffer();
    bool isFirst = true;
    sortedParamMap.forEach((key, value) {
      if (!isFirst) buffer.write("&");
      buffer.write(percentEncodeRfc3986(key));
      buffer.write("=");
      buffer.write(percentEncodeRfc3986(value));
      isFirst = false;
    });
    String canonical = buffer.toString();
    return canonical;
  }

  static String percentEncodeRfc3986(String s) {
    String out = Uri.encodeComponent(s);
    //out = URLEncoder.encode(s, UTF8_CHARSET)
    //    .replace("+", "%20")
    //    .replace("*", "%2A")
    //    .replace("%7E", "~");
    return out;
  }

  static String percentDecodeRfc3986(String s) {
    String out = Uri.decodeComponent(s);
    //out = URLDecoder.decode(s, UTF8_CHARSET)
    //      .replace("%20", "+")
    //      .replace("%2A", "*")
    //      .replace("~", "%7E");
    return out;
  }
}