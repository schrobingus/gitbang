# GitBang
A small and minimal Git GUI client written in Flutter.

## Introduction
The program functions very similarly to Git CLI, but is much more mouse based. 
- To open, clone, or initialize a repository, hit the "+" icon in the top left. Once you load a repository, you'll be given a list of files and their statuses.
- On the far left of each file is an icon. If it's **blank**, then the file has been unchanged from the repository. If it's **red**, that means that there are changes not staged for commit, and **green** means that all changes are staged. If it's **purple**, that means that some changes are staged, while there are also some that aren't.
  - Click on the icon to toggle between staged and unstaged.
  - If a name is greyed out, that means that the file is deleted but cached.
- Once you are finished, you have a selection of options by clicking on the 3 dots icon on the top right. You can make a new commit with the staged changes, revert a previous commit based on it's ID, pull (download) commits or push (upload) new commits.
  - More options also include a list of stashes (and an interface to make new stashes), a list of branches, and a commit history option.

## Demonstration
A video of GitBang in action performing basic Git tasks can be found [here.](https://www.youtube.com/watch?v=CyQHwP7_Xgk)
