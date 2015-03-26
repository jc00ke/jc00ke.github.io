---
layout: post
title: Fixing preferred browser in XFCE
author: Jesse
tags:
- xfce
- linux
---

At some point my preferred browser got out of sync. By this I mean I installed
Chrome unstable and Firefox, and different apps would open different browsers.
Clicking on a link in the terminal would open Firefox even though (stable)
Chrome was my preferred browser.

After a little digging I found [this
comment](https://bugs.launchpad.net/ubuntu/+source/chromium-browser/+bug/794720/comments/22)
on the Ubuntu bug tracker and it helped sort out my preferences.

{% highlight diff %}
--- /usr/share/applications/defaults-old.list 2015-03-25 10:25:14.905796546 -0700
+++ /usr/share/applications/defaults.list 2015-03-25 10:27:02.195005915 -0700
@@ -271,6 +271,6 @@
 text/xml=firefox.desktop;google-chrome.desktop;google-chrome-unstable.desktop
 application/xhtml_xml=google-chrome.desktop;;google-chrome-unstable.desktop
 image/webp=google-chrome.desktop;;google-chrome-unstable.desktop
-x-scheme-handler/http=firefox.desktop;google-chrome.desktop;google-chrome-unstable.desktop
-x-scheme-handler/https=firefox.desktop;google-chrome.desktop;google-chrome-unstable.desktop
+x-scheme-handler/http=google-chrome-unstable.desktop;google-chrome.desktop;firefox.desktop
+x-scheme-handler/https=google-chrome-unstable.desktop;google-chrome.desktop;firefox.desktop
 x-scheme-handler/ftp=google-chrome.desktop;;google-chrome-unstable.desktop
{% endhighlight %}

{% highlight diff %}
--- /etc/gnome/defaults-old.list 2015-03-25 10:24:45.492371994 -0700
+++ /etc/gnome/defaults.list 2015-03-25 10:26:01.676061182 -0700
@@ -259,6 +259,6 @@
 x-content/image-picturecd=shotwell.desktop
 zz-application/zz-winassoc-xls=libreoffice-calc.desktop
 x-scheme-handler/apt=ubuntu-software-center.desktop
-x-scheme-handler/http=firefox.desktop
-x-scheme-handler/https=firefox.desktop
+x-scheme-handler/http=google-chrome-unstable.desktop
+x-scheme-handler/https=google-chrome-unstable.desktop
 x-scheme-handler/mailto=thunderbird.desktop
{% endhighlight %}

I also noticed that Firefox had taken over `text/xml` and that Chrome was set to
open `image/webp` so I fixed those too. This is all a bit of a PITA, and
counter-intuitive to how preferred apps should work. I should set them in one
place and all apps should read from that source.

Anyway, hope this helps.

## Update

Turns out Firefox kept hold of certain things, so I uninstalled it. Didn't use
it much anyway.
