# uricut

A small command line utility for printing selected parts of URIs. Kinda like `cut` but for parsing URIs.

# Installation

Binaries for all supported platforms are available for download on the [releases page](https://github.com/matt-allan/uricut/releases).

If you're looking for a one liner to download the binary, you can use this:

```
URICUT_ARCH=x86_64-linux; curl -L https://github.com/matt-allan/uricut/releases/download/0.1.0/${URICUT_ARCH}.tar.xz | tar -xJ --strip-components=1 -C .
```

Replace the `URICUT_ARCH` variable with the architecture you want. The binary will be available in your current directory as `uricut`. Available architectures:

- `aarch64-linux`
- `aarch64-macos`
- `x86_64-linux-musl` 
- `x86_64-linux`
- `x86_64-macos`

You can also download binaries for unreleased versions from the [latest successful build on the main branch](https://github.com/matt-allan/uricut/actions).

# Usage

The `uricut` binary expects input on STDIN and writes to STDOUT. By default all URI components will be printed, separated by tabs:

```sh
$ echo 'https://destructure.co/uricut?v=0.1.0#usage' | uricut
https           destructure.co  /uricut v=0.1.0 usage
```

You can limit the output to specific components with the `-c` / `--component` flag. The following components are accepted:

- scheme
- username
- host
- port
- path
- query
- fragment
