import 'package:flutter/material.dart'; // Flutter Material dependency.
import 'package:gitbang/dialogs/error.dart'; // Error dialog worst-case.

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

            try {
              await revertCommitFunction(revertCommit.text, revertMessage.text);
            } catch(e) {
              Future.delayed(
                  const Duration(seconds: 0),
                      () => showDialog(
                      context: context,
                      builder:
                          (BuildContext context) {
                        return errorMessageDialog(
                            context,
                            "Unable to revert commit.");
                      }));
            }
          },
          child: const Text("Apply")),
    ],
  );
}
