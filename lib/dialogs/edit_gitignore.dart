import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart'; // Flutter Material dependency.

AlertDialog editGitignoreDialog(
    BuildContext context, String location, String current, refresh) {
  String correctedCurrent = current != "" ? "$current/" : "";
  TextEditingController ignored = TextEditingController(
      text: File("$location/$correctedCurrent.gitignore").existsSync()
          ? File("$location/$correctedCurrent.gitignore").readAsStringSync()
          : "");

  return AlertDialog(
    title: const Text('Edit Gitignore'),
    content: Container(
      height: 270,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: TextField(
        controller: ignored,
        expands: true,
        maxLines: null,
        decoration: const InputDecoration(border: InputBorder.none),
        style: const TextStyle(
          fontFamily: 'Menlo',
          fontFamilyFallback: ['monospace'],
        ),
      ),
    ),
    actions: [
      TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel")),
      TextButton(
          onPressed: () async {
            // TODO: Finish up function later on, such as addressing previous directories.
            var result =
                await FilePicker.platform.pickFiles(allowMultiple: false);
            String? resultPath = result?.files.single.path;

            if (result != null) {
              ignored.value = TextEditingValue(
                  text:
                      "${ignored.text}\n${resultPath?.replaceFirst("$location/$current", "")}");
            }
          },
          child: const Text("Load File")),
      TextButton(
          onPressed: () async {
            Navigator.of(context).pop();

            if (!await File("$location/$correctedCurrent.gitignore").exists()) {
              File('$location/$correctedCurrent.gitignore')
                  .create(recursive: true);
            }

            await File("$location/$correctedCurrent.gitignore")
                .writeAsString(ignored.text);

            refresh();
          },
          child: const Text("Apply")),
    ],
  );
}
