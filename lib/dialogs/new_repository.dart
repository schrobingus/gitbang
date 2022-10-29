import 'package:flutter/material.dart'; // Flutter Material dependency.
import 'package:gitbang/dialogs/error.dart'; // Error dialog worst-case.

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

            try {
              newRepoFunction(locationResult);
            } catch(e) {
              Future.delayed(
                  const Duration(seconds: 0),
                      () => showDialog(
                      context: context,
                      builder:
                          (BuildContext context) {
                        return errorMessageDialog(
                            context,
                            "Unable to initialize repository.");
                      }));
            }
          },
          child: const Text("Yes")),
    ],
  );
}
