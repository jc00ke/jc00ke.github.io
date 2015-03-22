---
layout: post
title: "Patching xdg-open for magnet links"
tags: linux, xfce, torrent
---

`xdg-open` doesn't set the correct `$DE` variable, so the wrong open function
gets called. Here's a simple patch to `/usr/bin/xdg-open` to fix it.

![diff](/assets/posts/patching-xdg-open-for-magnet-links/xdg-open-gist-diff.png)

Apologies for the image, I could't figure out how to embed just the relevant
diff. [Here's](https://gist.github.com/jc00ke/26a97113bcf21b8e05a7/revisions) the whole
shebang.
