import 'dart:convert';
import 'package:basic_utils/basic_utils.dart' as bu;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart' as pc;
import 'package:shared_preferences/shared_preferences.dart';

class CryptoUtils {
  static const String _privateKeyKey = 'private_key';
  static const String _publicKeyKey = 'public_key';
  
  static final CryptoUtils _instance = CryptoUtils._internal();
  factory CryptoUtils() => _instance;
  CryptoUtils._internal();

  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>? _keyPair;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final privKeyStr = prefs.getString(_privateKeyKey);
    final pubKeyStr = prefs.getString(_publicKeyKey);

    if (privKeyStr != null && pubKeyStr != null) {
      try {
        final pubKey = bu.CryptoUtils.rsaPublicKeyFromPem(pubKeyStr);
        final privKey = bu.CryptoUtils.rsaPrivateKeyFromPem(privKeyStr);
        _keyPair = pc.AsymmetricKeyPair(pubKey, privKey);
        print("Loaded existing KeyPair");
      } catch (e) {
        print("Error loading keys: $e. Generating new ones.");
        await _generateAndSaveKeys();
      }
    } else {
      print("Generating new KeyPair...");
      await _generateAndSaveKeys();
    }
  }

  // Wrapper to access basic_utils static methods to avoid naming conflict with class name
  static pc.RSAPublicKey rsaPublicKeyFromPem(String pem) =>
      bu.CryptoUtils.rsaPublicKeyFromPem(pem);
      
  static pc.RSAPrivateKey rsaPrivateKeyFromPem(String pem) =>
      bu.CryptoUtils.rsaPrivateKeyFromPem(pem);

  Future<void> _generateAndSaveKeys() async {
    // Generate RSA KeyPair using basic_utils
    final pair = bu.CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final pubKey = pair.publicKey as pc.RSAPublicKey;
    final privKey = pair.privateKey as pc.RSAPrivateKey;

    _keyPair = pc.AsymmetricKeyPair(pubKey, privKey);
    
    // Save to Config
    final pemPub = bu.CryptoUtils.encodeRSAPublicKeyToPem(pubKey);
    final pemPriv = bu.CryptoUtils.encodeRSAPrivateKeyToPem(privKey);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_privateKeyKey, pemPriv);
    await prefs.setString(_publicKeyKey, pemPub);
    print("New KeyPair stored.");
  }

  String? getMyPublicKeyPem() {
    if (_keyPair == null) return null;
    return bu.CryptoUtils.encodeRSAPublicKeyToPem(_keyPair!.publicKey);
  }

  // --- Encryption Logic ---

  /// Encrypts a message for a receiver.
  String encryptMessage(String content, String receiverPublicKeyPem) {
    if (_keyPair == null) throw Exception("KeyPair not initialized");

    // 1. Generate a random AES key
    final aesKey = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);
    final aesEncrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    
    final encryptedContent = aesEncrypter.encrypt(content, iv: iv);

    // 2. Encrypt the AES key with Receiver's Public Key
    final receiverPubKey = bu.CryptoUtils.rsaPublicKeyFromPem(receiverPublicKeyPem);
    final rsaEncrypterReceiver = encrypt.Encrypter(encrypt.RSA(publicKey: receiverPubKey));
    final encryptedKeyForReceiver = rsaEncrypterReceiver.encrypt(aesKey.base64);

    // 3. Encrypt the AES key with My Public Key (for history)
    final myPubKey = _keyPair!.publicKey; 
    final rsaEncrypterSender = encrypt.Encrypter(encrypt.RSA(publicKey: myPubKey));
    final encryptedKeyForSender = rsaEncrypterSender.encrypt(aesKey.base64);

    // 4. Bundle it all
    final payload = {
      "iv": iv.base64,
      "content": encryptedContent.base64,
      "key_map": {
        "receiver": encryptedKeyForReceiver.base64,
        "sender": encryptedKeyForSender.base64
      }
    };

    return jsonEncode(payload);
  }

  /// Decrypts a received message JSON payload.
  String decryptMessage(String jsonPayload, {bool isMyMessage = false}) {
    if (_keyPair == null) throw Exception("KeyPair not initialized");
    
    try {
      final data = jsonDecode(jsonPayload);
      final String ivBase64 = data['iv'];
      final String contentBase64 = data['content'];
      final Map<String, dynamic> keyMap = data['key_map'];
      
      String? encryptedAesKeyBase64;
      if (isMyMessage) {
         encryptedAesKeyBase64 = keyMap['sender'];
      } else {
         encryptedAesKeyBase64 = keyMap['receiver'];
      }

      if (encryptedAesKeyBase64 == null) return "[Key Missing]";

      // 1. Decrypt AES Key using my Private Key
      final myPrivKey = _keyPair!.privateKey;
      final rsaDecrypter = encrypt.Encrypter(encrypt.RSA(privateKey: myPrivKey));
      
      final aesKeyBase64 = rsaDecrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedAesKeyBase64));
      
      // 2. Decrypt Content
      final aesKey = encrypt.Key.fromBase64(aesKeyBase64);
      final iv = encrypt.IV.fromBase64(ivBase64);
      final aesEncrypter = encrypt.Encrypter(encrypt.AES(aesKey));
      
      return aesEncrypter.decrypt(encrypt.Encrypted.fromBase64(contentBase64), iv: iv);
      
    } catch (e) {
      print("Decryption Error: $e");
      return "[Decryption Failed]";
    }
  }
}
