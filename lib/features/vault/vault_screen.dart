import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../player/player_screen.dart';
import 'vault_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final v = VaultService();
  bool unlocked = false;
  final pin = TextEditingController();
  List<FileSystemEntity> files = [];

  Future<void> _refresh() async { files = await v.list(); setState(() {}); }

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock, size: 64),
          SizedBox(width: 200, child: TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'PIN'))),
          FilledButton(onPressed: () async {
            if (!await v.hasPin()) await v.setPin(pin.text);
            if (await v.unlock(pin: pin.text)) { unlocked = true; _refresh(); }
          }, child: const Text('Unlock')),
          TextButton(onPressed: () async { if (await v.unlock()) { unlocked = true; _refresh(); } }, child: const Text('Use biometrics')),
        ]),
      );
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final r = await FilePicker.platform.pickFiles(type: FileType.video);
          if (r?.files.single.path != null) { await v.hide(r!.files.single.path!); _refresh(); }
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(children: [
        for (final f in files)
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(f.path.split('/').last.replaceAll('.enc', '')),
            onTap: () async {
              final p = await v.decryptToTemp(f.path);
              if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(path: p, title: p.split('/').last)));
            },
          ),
      ]),
    );
  }
}
