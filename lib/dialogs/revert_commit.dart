import 'package:flutter/material.dart';

AlertDialog revertCommitDialog(BuildContext context, var revertCommitFunction) {
  TextEditingController revertMessage = TextEditingController();
  TextEditingController revertCommit = TextEditingController();

  return AlertDialog(
    title: const Text('Revert Commit'),
    content: SizedBox(
      height: 100,
      child: Column(
        children: [
          TextField(
            controller: revertCommit,
            decoration: const InputDecoration(
              hintText: "Commit (ex: f668902)",
            ),
          ),
          TextField(
            controller: revertMessage,
            decoration: const InputDecoration(
              hintText: "Message",
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
          child: const Text("Cancel")),
      TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            revertCommitFunction(revertCommit.text, revertMessage.text);
          },
          child: const Text("Apply")),
    ],
  );
}
