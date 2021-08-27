import 'dart:collection';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/block/modes/ecb.dart';

class SignedRequestHelper {
  static final String UTF8_CHARSET = "UTF-8";
  static final String HMAC_SHA256_ALGORITHM = "HmacSHA256";
  static final String REQUEST_METHOD = "GET";

  late String accessString;
  late PaddedBlockCipher mac;
  late Uint8List secretKeySpec;

  SignedRequestHelper(String email, String secretKey) {
    if (secretKey == null) throw ArgumentError("SecretKey cannot be null");
    if(secretKey.length>16) throw ArgumentError("secretKey must be 16 characters or less");
    String paddingString="ASDFGHJKLASDFGHJ";
    String secretKeyPadded=paddingString.replaceRange(0, secretKey.length, secretKey);
    accessString = "email=" + percentEncodeRfc3986(email.toLowerCase()) + "&";
    Uint8List secretyKeyBytes;

    secretyKeyBytes = Uint8List.fromList(
      utf8.encode(secretKeyPadded),
    );
    mac = PaddedBlockCipherImpl(
      PKCS7Padding(), // Java defaults to PKCS5 which is equivalent
      ECBBlockCipher(
          AESFastEngine()), // Very weak mode - don't use this in the real world
    );
    mac.init(
      true,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        KeyParameter(secretyKeyBytes),
        null,
      ),
    );
    secretKeySpec = mac.process(utf8.encode(email) as Uint8List);
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
    String signature;
    Uint8List data;
    Uint8List rawHmac;
    data = Uint8List.fromList(utf8.encode(stringToSign));

    rawHmac = mac.process(data);
    signature = utf8.decode(rawHmac);

    return signature;
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
