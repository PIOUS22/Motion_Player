import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';

/// Hides videos by AES-encrypting them into app-private storage.
/// PIN and key live in the Android Keystore via flutter_secure_storage.
/// NOTE: whole file is held in memory; use chunked streaming encryption for very large videos.
class VaultService {
  final _store = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  Future<bool> hasPin() async => await _store.read(key: 'pin') != null;
  Future<void> setPin(String pin) => _store.write(key: 'pin', value: pin);

  Future<bool> unlock({String? pin}) async {
    if (pin != null) return pin == await _store.read(key: 'pin');
    return _auth.authenticate(localizedReason: 'Unlock Private folder');
  }

  Future<enc.Key> _key() async {
    var k = await _store.read(key: 'aes');
    if (k == null) { k = enc.Key.fromSecureRandom(32).base64; await _store.write(key: 'aes', value: k); }
    return enc.Key.fromBase64(k);
  }

  Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/.vault');
    return d.existsSync() ? d : d.create(recursive: true);
  }

  Future<void> hide(String path) async {
    final f = File(path), iv = enc.IV.fromSecureRandom(16);
    final out = enc.Encrypter(enc.AES(await _key(), mode: enc.AESMode.cbc)).encryptBytes(await f.readAsBytes(), iv: iv);
    await File('${(await _dir()).path}/${path.split('/').last}.enc').writeAsBytes([...iv.bytes, ...out.bytes]);
    await f.delete();
  }

  /// Decrypts to a temp file for playback; delete it afterwards.
  Future<String> decryptToTemp(String encPath) async {
    final b = await File(encPath).readAsBytes();
    final iv = enc.IV(Uint8List.fromList(b.sublist(0, 16)));
    final plain = enc.Encrypter(enc.AES(await _key(), mode: enc.AESMode.cbc)).decryptBytes(enc.Encrypted(Uint8List.fromList(b.sublist(16))), iv: iv);
    final t = File('${(await getTemporaryDirectory()).path}/${encPath.split('/').last.replaceAll('.enc', '')}');
    await t.writeAsBytes(plain);
    return t.path;
  }

  Future<List<FileSystemEntity>> list() async => (await _dir()).listSync().where((e) => e.path.endsWith('.enc')).toList();
}
