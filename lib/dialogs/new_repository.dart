import 'package:flutter/material.dart';

AlertDialog newRepoDialog(
    BuildContext context, var newRepoFunction, String locationResult) {
  return AlertDialog(
    title: const Text("New Repository"),
    content: const Text(
        "The following directory is not a Git repository. Would you like to initialize one here?"),
    actions: [
      TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("No")),
      TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            newRepoFunction(locationResult);
          },
          child: const Text("Yes")),
    ],
  );
}
