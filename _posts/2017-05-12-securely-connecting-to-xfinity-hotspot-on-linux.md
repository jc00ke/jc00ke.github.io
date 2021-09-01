---
layout: post
title: Securely connecting to XFINITY hotspot on Linux
author: Jesse
---

I've been coming to this coffee shop with this same network and same laptop for almost 2 years now. Today, for
some reason, my laptop decided it didn't want to play nicely with the network. I could connect to both the 2.4
and 5GHz networks but I couldn't ping anything... DNS issue?

The first thing I tried was setting my connection to use Google's DNS: `8.8.8.8` and `8.8.4.4` for `ipv4` and
`2001:4860:4860:8888` and `2001:4860:4860:8844` for `ipv6`.

No bueno.

Next step? Restart my computer.

No bueno.

I look around and see that there's `xfinitywifi` and `XFINITY` networks, and I'm reminded that I can connect
and that the `XFINITY` has a secure connection capability. Some googlin' brings me to [this support
page](https://www.xfinity.com/support/internet/about-xfinity-wifi-internet/#secure_support). Well shit, Linux
isn't supported. I decide to give it a go anyway, and I'm presented with this screen:

![Network settings dialog in GNOME](/assets/posts/securely-connecting-to-xfinity-hotspot-on-linux/network-settings-dialog.png)

I filled in those values based on the [suggestions for Android
from](https://www.xfinity.com/support/internet/connect-manually-secure-xfinity-wifi-hotspots/).

Well, initially I had `No CA certificate is required` but that didn't feel right, so, more googlin' and I
found [this AskUbuntu answer](https://askubuntu.com/a/781026) that suggested the `AddTrust_External_Root.ca`.

_Update_ - Thanks to [@variuxdavid](https://twitter.com/variuxdavid/status/1433208622901772288) for letting
me know there's a new `CA certificate` for later versions of Ubuntu: `COMODO_RSA_Certification_Authority.crt`.
Screenshot updated!

Lo and behold, it worked!

Now, am I 100% certain this is the same security level as what XFINITY is claiming on other platforms? No, but
I'm like 95% and that's good enough for the next few hours.
