<div align="center">

# asdf-flutter [![Build](https://github.com/fejzuli/asdf-flutter/actions/workflows/build.yml/badge.svg)](https://github.com/fejzuli/asdf-flutter/actions/workflows/build.yml) [![Lint](https://github.com/fejzuli/asdf-flutter/actions/workflows/lint.yml/badge.svg)](https://github.com/fejzuli/asdf-flutter/actions/workflows/lint.yml)

[flutter](https://docs.flutter.dev) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

General: `curl`, `grep`, `sed`, `awk`

Linux: `tar`

MacOS: `unzip`

On apple silicon rosetta needs to be installed. You can manually install it with
```shell
sudo softwareupdate --install-rosetta --agree-to-license
```

# Install

Plugin:

```shell
asdf plugin add flutter https://github.com/fejzuli/asdf-flutter.git
```

flutter:

```shell
# Show all installable versions
asdf list-all flutter

# Install specific version
asdf install flutter latest

# Set a version globally (on your ~/.tool-versions file)
asdf global flutter latest

# Now flutter commands are available
flutter doctor
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/fejzuli/asdf-flutter/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Merlin Attila Fejzuli](https://github.com/fejzuli/)
