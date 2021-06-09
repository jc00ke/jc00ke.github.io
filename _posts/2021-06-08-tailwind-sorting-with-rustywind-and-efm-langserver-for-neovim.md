---
title: Automatically sort Tailwind classes in Neovim with rustywind and efm-langserver
layout: post
description: Inspired by Dr. Nic, wire up efm-langserver with rustywind to get auto-sorting in Neovim 0.5+
author: Jesse
tags:
- neovim
- lsp
- efm
- tailwind
---

Neovim 0.5 has a built-in language server client (LSP) that's easily extensible
with the [efm-langserver](https://github.com/mattn/efm-langserver). Inspired by Dr. Nic's
[recent post on dev.to](https://dev.to/drnic/automatically-sorting-your-tailwind-css-class-names-4gej)
I wanted to get [rustywind](https://github.com/avencera/rustywind)
working with efm-langserver. I don't even use Tailwind... yet,
but I've been a fan for quite a while.

I'll leave it to the reader to get efm-langserver installed, but I wanted to share my config.
I use `~/.config/efm-langserver/config.yaml` to configure formatters & linters, and I configure
`efm` in Neovim in `~/.config/nvim/init.lua`. Here are the relevant parts:

#### efm-langserver config

{% highlight yaml %}
version: 2

tools:
  tailwind-class-sort: &tailwind-class-sort
    format-command: 'rustywind --stdin'
    format-stdin: true

languages:
  html:
    - <<: *tailwind-class-sort
{% endhighlight %}

#### neovim lua config

{% highlight lua %}
lspconfig.efm.setup({
  filetypes = {"html"},
  init_options = {documentFormatting = true},
})
{% endhighlight %}

Check out my [dotfiles repo 
commit](https://github.com/jc00ke/dotfiles/commit/dbe31441fedf4325572d622c8c940ce47b1e292e?branch=dbe31441fedf4325572d622c8c940ce47b1e292e&diff=unified)
and you can view more of the files to see how they're all put together. Now, when you write the file,
you'll get automatic class sorting. Fun stuff!
