import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gitbang/config.dart'; // Flutter Material dependency.

class EditGitignoreDialog extends StatefulWidget {
  final String location;
  final String current;
  final VoidCallback refresh;

  const EditGitignoreDialog(this.location, this.current, this.refresh);

  @override
  State<EditGitignoreDialog> createState() => _EditGitignoreDialogState();
}

class _EditGitignoreDialogState extends State<EditGitignoreDialog> {
  @override
  Widget build(BuildContext context) {
    String correctedCurrent = widget.current != "" ? "${widget.current}/" : "";
    TextEditingController ignored = TextEditingController(
        text:
            File("${widget.location}/$correctedCurrent.gitignore").existsSync()
                ? File("${widget.location}/$correctedCurrent.gitignore")
                    .readAsStringSync()
                : "");

    return AlertDialog(
      title: const Text('Edit Gitignore'),
      content: Container(
        height: 270,
        decoration: BoxDecoration(
          border: Border.all(
            color: Config.foregroundColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: TextField(
            controller: ignored,
            expands: true,
            maxLines: null,
            decoration: const InputDecoration(border: InputBorder.none),
            style: Config.theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'Menlo',
              fontFamilyFallback: ['monospace'],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: Config.theme.textButtonTheme.style,
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
                        "${ignored.text}\n${resultPath?.replaceFirst("${widget.location}/${widget.current}", "")}");
              }
            },
            style: Config.theme.textButtonTheme.style,
            child: const Text("Load File")),
        TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              if (!await File("${widget.location}/$correctedCurrent.gitignore")
                  .exists()) {
                File('${widget.location}/$correctedCurrent.gitignore')
                    .create(recursive: true);
              }

              await File("${widget.location}/$correctedCurrent.gitignore")
                  .writeAsString(ignored.text);

              widget.refresh();
            },
            style: Config.theme.textButtonTheme.style,
            child: const Text("Apply")),
      ],
    );
  }
}
