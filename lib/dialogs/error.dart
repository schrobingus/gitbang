import 'package:flutter/material.dart'; // Flutter Material dependency.

/* The error dialog needs to be simple, so it can be loaded quickly.
* There should also be no complex styling applied in the scenario that
* the styling itself fails.*/
AlertDialog errorMessageDialog(BuildContext context, String errorMessage) {
  return AlertDialog(
    title: const Text("Oops!", style: TextStyle(color: Colors.red)),
    content: Text(errorMessage),
    actions: [
      TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Dismiss")),
    ],
  );
}
