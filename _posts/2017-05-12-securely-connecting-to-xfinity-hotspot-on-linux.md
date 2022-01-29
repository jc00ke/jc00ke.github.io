---
layout: post
title: Securely connecting to XFINITY hotspot on Linux
author: Jesse
tags:
  - wifi
  - comcast
  - xfinity
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

Lo and behold, it worked!

Now, am I 100% certain this is the same security level as what XFINITY is claiming on other platforms? No, but
I'm like 95% and that's good enough for the next few hours.

_Update_ - Thanks to [@variuxdavid](https://twitter.com/variuxdavid/status/1433208622901772288) for letting
me know there's a new `CA certificate` for later versions of Ubuntu: `COMODO_RSA_Certification_Authority.crt`.
Screenshot updated!

_Update_ - Chris Lopes reached out suggesting some improvements to this post. I've not been on Comcast for years,
but this post keeps coming up in searches so I want to include his advice:

> It seems that although GTC inner authentication works in order to connect to the hotspot, it does not (any longer?)
> allow actual use of the network without first logging in to the captive portal (Xfinity web login page),
> which is often hard to get to, believe it or not. The solution seems to be to use PAP instead, which solves this.

He also sent a [link to an AskUbuntu answer](https://askubuntu.com/a/1385684) that I hope can be helpful.

For those on Apple devices that might find their way here, I want to include Chris's side note:

> I also checked, and the .mobileconfig automatic [configuration profiles](https://developer.apple.com/business/documentation/Configuration-Profile-Reference.pdf)
> that Xfinity provides to MacOS
> and iOS devices for use with the Hotspots now also list PAP as the inner authentication.
> There are files that you download and "install" on Apple devices to provision similar settings automatically as the ones we are discussing here.
> Xfinity interestingly generates some sort of separate credentials that are just for this purpose
> (totally different username/password than the one you would normally use).
> You can test this via the captive portal if you spoof your User Agent to be an apple device and have it generate the profile for you to download.

Some terms that I hope help you find your way here according to Chris:

- GTC
- PAP
- Tunneled TLS and TTLS
- [EAP-TTLS](https://en.wikipedia.org/wiki/Extensible_Authentication_Protocol#EAP-TTLS)
- [Passpoint / Hotspot 2.0](<https://en.wikipedia.org/wiki/Hotspot_(Wi-Fi)#Hotspot_2.0>)

I love receiving updates for this post! You keep sending them and I'll keep updating.
