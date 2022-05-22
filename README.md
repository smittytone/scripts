# Smittytone’s Script Archive #

*Useful zsh and bash scripts*

In the case of scripts which operate as utilities, use the `--help` switch to learn how to make use of the tool. Scripts which are intended to be run once &mdash; for example, the Raspberry Pi setup scripts &mdash; are documented in comments. Scripts run in other contexts, eg. in Xcode, are not yet documented.

## Tools and Utilities ##

### outman.zsh ###

Output man pages to text files. Specify the page and its output text file as pairs of arguments.

- [View Script](outman.zssh)

### image&lt;num/prep&gt;.sh ###

Image processing scripts. See [this blog post](https://smittytone.wordpress.com/2019/10/24/macos-image-manipulation-with-sips/).

**Note** imageprep 5.2.0 reverses the order of crop, scale and pad dimensions *from* <height> <width> *to* <width> <height>.

- [View Image Cropping/Padding/Scaling Script](imageprep.sh)
- [View Image Numbering Script](imagenum.sh)

### cs.sh ###

Confirm or reject a downloaded file’s SHA-256.

- [View Script](cs.sh)

### lowerext.sh ###

Convert the working directory’s file extensions to lowercase.

- [View Script](lowerext.sh)

### pdfer.sh ###

Converts `.docx` files downloaded from Google Docs to `.pdf`.

- [View Script](pdfer.sh)

### cbz_blitzer.sh ###

Scans a folder (and sub-folders) for .cbz files and converts them to .pdf files. Created for a one-off project. Included here to record folder scanning and file manipulation algorithms.

- [View Script](cbz_blitzer.sh)

## Xcode and Development ##

### iconprep.sh ###

macOS/watchOS/iOS app icon maker script.

- [View Script](iconprep.sh)

### xcodeautobuild.sh ###

Xcode-oriented build script for auto-incrementing a project's build number at build time.

- [View Script](xcodeautobuild.sh)

### packcli.zsh and packapp.zsh ###

Shell scripts to automate the creation of macOS app installer packages, and their signing and notarization. For use with apps distributed outside the Mac App Store.

- [View packapp Script](packapp.zsh)
- [View packcli Script](packcli.zsh)

## Mac Setup and Config ##

### updatemac.zsh / updatemac.sh ###

Update local config files from the `dotfiles` repo.

- [View bash Script](updatemac.sh)
- [View zsh Script](updatemac.zsh)

### setupmac.sh ###

Set up a new Mac.

- [View Script](setupmac.sh)

## Mac Backup ##

### to&lt;disk/server&gt;.sh ###

Local media back-up scripts, targeting disk and server.

- [View Disk Script](todisk.sh)
- [View Server Script](toserver.sh)

## Raspberry Pi Setup and Config ##

### updatepi.zsh / updatepi.sh ###

Update local config files from the `dotfiles` repo.

- [View bash Script](updatepi.sh)
- [View zsh Script](updatepi.zsh)

### &lt;p/z&gt;install.sh ###

Setup scripts for the Raspberry Pi and the Raspberry Pi Zero.

- [View Raspberry Pi Script](pinstall.sh)
- [View Pi Zero Script](zinstall.sh)

### pi.sh ###

SD card preparation script for Raspberry Pis. **Note** This runs on a macOS host.

- [View Script](pi.sh)

### pireadonly.sh ###

Hack a Raspberry Pi to run in read-only mode (no writes to the SD).

- [View Script](pireadonly.sh)

## Miscellaneous ##

### cppy.zsh ###

Copy a bunch of Python files to a CircuitPython device. The first file on the list is renamed `code.py`.

- [View Script](cppy.zsh)