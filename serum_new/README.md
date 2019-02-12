# mix serum.new

Install this archive to use `serum.new` installer.

## Installation

### Building from Source

Since this is still in development, this package is not published to Hex yet.
So you need to build and install on your own.

1. Make sure you uninstall any previously installed archives.

    ```
    $ mix archive.uninstall serum_new
    ```

2. Build and install the new archive.

    ```
    $ MIX_ENV=prod mix do archive.build, archive.install
    ```
