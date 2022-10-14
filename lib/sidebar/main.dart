import 'dart:io';
import 'package:flutter/material.dart';

class _SidebarState extends State<Sidebar> {
  var _historyPageNumber = 0;

  @override
  Widget build(BuildContext context) {
    Color selectedColor(String i) {
      if (i[0] == '*') {
        if (i.contains("detached")) {
          return Colors.red;
        } else {
          return Colors.blue;
        }
      } else {
        return Colors.black;
      }
    }

    return Drawer(
      child: SingleChildScrollView(
        child: Column(children: [
          if (widget.sidebarContent == "branches") ...[
            const Padding(
              padding: EdgeInsets.only(
                  left: 10.0, right: 10.0, top: 20.0, bottom: 15.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text("Local"),
              ),
            ),
            for (var i = 0; i < widget.sidebarBranches.length; i++) ...[
              if (!widget.sidebarBranches[i]
                  .substring(2, widget.sidebarBranches[i].length)
                  .split(" -> ")
                  .last
                  .startsWith("remotes/")) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        void checkoutBranch() async {
                          await Process.start(
                              "git",
                              [
                                "checkout",
                                widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length)
                                    .split(" -> ")
                                    .last
                              ],
                              workingDirectory: widget.targetLocation);
                        }

                        if (!widget.sidebarBranches[i]
                            .substring(2, widget.sidebarBranches[i].length)
                            .startsWith("(")) {
                          checkoutBranch();
                        }
                        Navigator.pop(context);
                      },
                      child: Stack(
                        children: [
                          Text(
                            /*widget.sidebarBranches[i]
                                .substring(2, widget.sidebarBranches[i].length)
                                .split(" -> ")
                                .last,*/
                            (() {
                              if (widget.sidebarBranches[i].contains("(")) {
                                return widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length - 1)
                                    .split(" ")
                                    .last;
                              } else {
                                return widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length)
                                    .split(" -> ")
                                    .last;
                              }
                            }()),
                            style: TextStyle(
                                color:
                                    selectedColor(widget.sidebarBranches[i])),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
            GestureDetector(
              child: const Text("+ Add New"),
              onTap: () {
                TextEditingController branchName = TextEditingController();
                Future.delayed(
                    const Duration(seconds: 0),
                    () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('New Branch'),
                            content: TextField(
                              controller: branchName,
                              decoration: const InputDecoration(
                                hintText: "Branch Name (ex: 'master')",
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

                                    Process.run("git",
                                        ["checkout", "-b", branchName.text],
                                        workingDirectory:
                                            widget.targetLocation);
                                  },
                                  child: const Text("Add")),
                            ],
                          );
                        }));
              },
            ),
            const Padding(
              padding: EdgeInsets.only(
                  left: 10.0, right: 10.0, top: 20.0, bottom: 15.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text("Remote"),
              ),
            ),
            for (var i = 0; i < widget.sidebarBranches.length; i++) ...[
              if (widget.sidebarBranches[i]
                  .substring(2, widget.sidebarBranches[i].length)
                  .split(" -> ")
                  .last
                  .startsWith("remotes/")) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        void checkoutBranch() async {
                          await Process.start(
                              "git",
                              [
                                "checkout",
                                widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length)
                                    .split(" -> ")
                                    .last
                              ],
                              workingDirectory: widget.targetLocation);
                        }

                        checkoutBranch();
                        Navigator.pop(context);
                      },
                      child: Text(
                        widget.sidebarBranches[i]
                            .substring(2, widget.sidebarBranches[i].length)
                            .split(" -> ")
                            .last,
                        style: TextStyle(
                            color: selectedColor(widget.sidebarBranches[i])),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ] else if (widget.sidebarContent == "history") ...[
            Column(
              children: [
                for (var i = 0; i < 25; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                            widget.sidebarHistoryInitialCut[_historyPageNumber]
                                [i][0]),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                              widget.sidebarHistoryInitialCut[
                                  _historyPageNumber][i][1],
                              textAlign: TextAlign.right),
                        ),
                      ),
                    ],
                  ),
                ],
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_double_arrow_left),
                          padding: const EdgeInsets.all(0.0),
                          onPressed: () {
                            setState(() {
                              if (_historyPageNumber > 0) {
                                _historyPageNumber = 0;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_left),
                          padding: const EdgeInsets.all(0.0),
                          onPressed: () {
                            setState(() {
                              _historyPageNumber--;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          "$_historyPageNumber",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right),
                          padding: const EdgeInsets.all(0.0),
                          onPressed: () {
                            setState(() {
                              if (_historyPageNumber <
                                  widget.sidebarHistoryInitialCut.length - 1) {
                                _historyPageNumber++;
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_double_arrow_right),
                          padding: const EdgeInsets.all(0.0),
                          onPressed: () {
                            setState(() {
                              _historyPageNumber =
                                  widget.sidebarHistoryInitialCut.length - 1;
                            });
                          },
                        ),
                      ),
                    ]),
              ],
            ),
          ],
        ]),
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  final String sidebarContent;
  final List sidebarBranches;
  final List sidebarHistoryInitialCut;
  final String targetLocation;

  const Sidebar(this.sidebarContent, this.sidebarBranches,
      this.sidebarHistoryInitialCut, this.targetLocation);

  @override
  State<Sidebar> createState() => _SidebarState();
}
