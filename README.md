# Serum

[![Build Status](https://travis-ci.org/Dalgona/Serum.svg?branch=master)](https://travis-ci.org/Dalgona/Serum)
[![Coverage Status](https://coveralls.io/repos/github/Dalgona/Serum/badge.svg?branch=v1/master)](https://coveralls.io/github/Dalgona/Serum?branch=v1/master)

**Serum** is a simple static website generator written in
[Elixir](http://elixir-lang.org).

Like some of other static website generators, Serum focuses on blogging. And if
you know how to write markdown documents and how to handle EEx templates, you
can easily build your own website.

## Getting Started

Use Mix to install the Serum installer archive from Hex.

```sh
$ mix archive.install hex serum_new
```

You can now use `serum.new` Mix task to create a new Serum project.

```sh
$ mix serum.new /path/to/new_website
```

`cd` into the new project directory and install Serum.

```sh
$ cd /path/to/new_website
$ mix do deps.get, deps.compile
```

Try building the website, or spin up the development server.

```sh
# Your website will be built at /path/to/new_website/site
$ mix serum.build

# Your website will be built and served at http://localhost:8080
$ mix serum.server
```

Please visit [the official website](http://dalgona.github.io/Serum) for
more guides and documentations.

## LICENSE

Copyright (c) 2022 Eunbin Jeong (Dalgona.) <project-serum@dalgona.dev>

MIT License. Read `LICENSE` for the full text.
