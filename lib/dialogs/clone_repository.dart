import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';

AlertDialog cloneRepositoryDialog(BuildContext context, var cloneRepoFunction) {
  TextEditingController repositoryToClone = TextEditingController();
  TextEditingController locationToCloneTo = TextEditingController();

  return AlertDialog(
    title: const Text('Clone Repository'),
    content: SizedBox(
      height: 100,
      child: Column(
        children: [
          TextField(
            controller: repositoryToClone,
            decoration: const InputDecoration(
              hintText: "Repository",
            ),
          ),
          TextField(
            controller: locationToCloneTo,
            decoration: InputDecoration(
              hintText: "Location",
              suffixIcon: IconButton(
                icon: const Icon(Icons.create_new_folder),
                onPressed: () async {
                  locationToCloneTo.text =
                      (await FilePicker.platform.getDirectoryPath())!;
                },
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
          child: const Text("Cancel")),
      TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            cloneRepoFunction(repositoryToClone.text, locationToCloneTo.text);
          },
          child: const Text("Clone")),
    ],
  );
}
