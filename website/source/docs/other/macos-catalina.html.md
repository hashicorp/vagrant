---
layout: "docs"
page_title: "Vagrant and macOS Catalina"
sidebar_current: "other-macos-catalina"
description: |-
  An overview of using Vagrant on macOS Catalina.
---

# Vagrant and macOS Catalina

The latest version of macOS (Catalina) includes security changes that prevent
applications from accessing data in your Documents, Desktop, and Downloads
folders without explicit permission. If you keep any virtual machine files in
these folders, you will need to allow access to these folders for your terminal
emulator.

Initially when you try to access one of these folders from the command line, you
should see a popup that says something like:

> “Terminal” would like to access files in your Documents folder.

Click "OK" to grant those permissions.

If you click "Don't Allow" and find that you need to grant access later on, you
can go to "System Preferences" -> "Security & Privacy" -> "Files and Folders"
and you should see your terminal emulator there. Click on the lock, and then
click on the checkbox next to the folder that contains the files that Vagrant
needs to access.

Note that granting the `vagrant` binary "Full Disk Access" is not sufficient or
necessary. If Terminal (or iTerm2/Hyper/etc.) is granted access to a particular
folder, then Vagrant will also be able to access that folder.
