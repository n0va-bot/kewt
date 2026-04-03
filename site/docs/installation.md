---
title = "Installation"
priority = 0
---
# Installation

## Standalone

```sh
curl -L -o kewt https://git.krzak.org/N0VA/kewt/releases/download/latest/kewt
chmod +x kewt
```
## From source

```sh
git clone https://git.krzak.org/N0VA/kewt.git
cd kewt
```
### Building

```sh
make
```
### Installing

```sh
sudo make install
```
## Package Managers

### AUR

- [kewt-bin](https://aur.archlinux.org/packages/kewt-bin) - prebuilt standalone binary from the latest release
- [kewt-git](https://aur.archlinux.org/packages/kewt-git) - built from the latest git source

### Homebrew

```sh
brew tap n0va-bot/tap
brew install kewt
```
### bpkg

```sh
bpkg install n0va-bot/kewt
```
