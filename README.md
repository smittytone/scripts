# Smittytone’s Script Archive #

*Useful bash scripts*

In the case of scripts which operate as utilities, use the `--help` switch to learn how to make use of the tool. Scripts which are intended to be run once &mdash; for example, the Raspberry Pi setup scripts &mdash; are documented in comments. Scripts run in other contexts, eg. in Xcode, are not yet documented.

## Tools and Utilities ##

### image&lt;num/prep&gt;.sh ###

Image processing scripts. See [this blog post](https://smittytone.wordpress.com/2019/10/24/macos-image-manipulation-with-sips/).

- [View Image Cropping/Padding/Scaling Script](imageprep.sh)
- [View Image Numbering Script](imagenum.sh)

### lowerext.sh ###

Convert the working directory’s file extensions to lowercase

- [View Script](lowerext.sh)

### upconf.sh ###

Update local config files from the `dotfiles` repo

- [View Script](upconf.sh)

### to&lt;disk/server&gt;.sh ###

Local media back-up scripts, targeting disk and server.

- [View Disk Script](todisk.sh)
- [View Server Script](toserver.sh)

### pdfer.sh ###

Converts `.docx` files downloaded from Google Docs to `.pdf`.

- [View Script](pdfer.sh)

## Xcode and Development ##

### iconprep.sh ###

macOS/watchOS/iOS app icon maker script

- [View Script](iconprep.sh)

### xcodeautobuild.sh ###

Xcode-oriented build script for auto-incrementing a project's build number at build time

- [View Script](xcodeautobuild.sh)

## Raspberry Pi ##

### pireadonly.sh ###

Hack a Raspberry Pi to run in read-only mode (no writes to the SD).

- [View Script](pireadonly.sh)

### &lt;p/z&gt;install.sh ###

Setup scripts for the Raspberry Pi and the Raspberry Pi Zero.

- [View Raspberry Pi Script](pinstall.sh)
- [View Pi Zero Script](zinstall.sh)

### pi.sh ###

SD card preparation script for Raspberry Pis. **Note** This runs on a macOS host.

- [View Script](pi.sh)