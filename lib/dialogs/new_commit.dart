import 'package:flutter/material.dart'; // Flutter Material dependency.
import 'package:gitbang/config.dart';
import 'package:gitbang/dialogs/error.dart'; // Error dialog worst-case.

AlertDialog newCommitDialog(
    BuildContext context, var newCommitFunction, String commitChanges) {
  TextEditingController commitMessage = TextEditingController();

  return AlertDialog(
    title: const Text('New Commit'),
    content: SizedBox(
      height: 200,
      child: Column(
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              style: Config.theme.textTheme.bodyLarge,
              controller: commitMessage,
              decoration: Config.inputDecoration.copyWith(
                hintText: "Message",
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 30.0, bottom: 5.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text("Items to be committed:"),
            ),
          ),
          Container(
            width: 240,
            height: 80,
            decoration: BoxDecoration(
                border: Border.all(
              color: Config.foregroundColor,
              width: 1,
            )),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SelectableText(
                    commitChanges,
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      fontFamilyFallback: ['monospace'],
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
            Navigator.of(context).pop();

            try {
              newCommitFunction(commitMessage.text);
            } catch (e) {
              Future.delayed(
                  const Duration(seconds: 0),
                  () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return errorMessageDialog(
                            context, "Unable to create commit.");
                      }));
            }
          },
          style: Config.theme.textButtonTheme.style,
          child: const Text("Apply")),
    ],
  );
}
