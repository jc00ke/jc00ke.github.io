---
layout: post
title: Setting your Hex org auth key with the Heroku Elixir buildpack
description: Using ENV vars because checking in keys is bad news
author: Jesse
tags:
- elixir
- hex
- heroku
- buildpack
- TIL
---

I've been working on an Elixir application for the last year, and overall it's been a smooth, pleasant
experience. I've been meaning to write more, so here we go.

[Hex](https://hex.pm/), the package manager for [Elixir](https://elixir-lang.org) is very well thought out,
but there are things I'm still being introduced to, like [private organizations](https://hex.pm/docs/private).
There's a beta I'm trying out, and it requires me to use a hex org key, which is fine, but how do I securely
store it in Heroku such that it's available when installing packages?

My first attempt was to set the `hook_pre_fetch_dependencies` hook of the excellent [buildpack for
Heroku](https://github.com/HashNuke/heroku-buildpack-elixir) like so:

```bash
hook_pre_fetch_dependencies="mix hex.organization auth acme --key $HEX_ORG_KEY_FOR_ACME"
```

I pushed to Heroku and...

```bash
-----> Executing hook before fetching app dependencies: mix hex.organization auth acme --key

** (Mix) Could not invoke task "hex.organization": 1 error found!

--key : Missing argument of type string
```

Luckily, I had already set up a `postdeploy` script for Heroku's `app.json` so I had that method in mind,
however, there wasn't a hook in that lifecycle that made sense for me to use. But, mixing the two approaches
did seem like something worth trying, and this is what ended up working.

In `./bin/predeps`

```bash
#!/bin/bash

mix hex.organization auth acme --key "$HEX_ORG_KEY_FOR_ACME"
```

In `elixir_buildpack.config`

```bash
hook_pre_fetch_dependencies="./bin/predeps"
```

Worked, and feels clean enough!
