---
layout: post
title: 'Going native: Pidgin, Geary and California'
author: Jesse
tags:
- linux
- xfce
- geary
- california
---

For years I've had 2 Gmail tabs pinned in Chrome: personal and work. This took
care of email, IM and calendar, which was quite convenient. I'm tired of waiting
for those 2 tabs to load when I spin up my browser, and I also WANT MY RAM BACK!

So, I've decided to go native for a bit. 3 concerns:

## Instant Message

Pidgin is king here, especially on Linux. While the buddy list is overpopulated
with people I don't chat with, or have never chatted with, it's easy to clean it
up. I need to learn the keyboard shortcuts, otherwise I think it'll work out
well.

The only thing I'd like to add is SMS support. I already use MightyText and
luckily there is already a
[pidgin-mightytext](https://github.com/tubaman/pidgin-mightytext) plugin. Just
need to compile it and get it set up. Hopefully it works.

## Email

Gmail is fast and powerful. Evolution and Thunderbird are both too bloated and
ugly for my tastes, so I'm left with [Geary](https://wiki.gnome.org/Apps/Geary)
from the [Yorba Foundation](http://yorba.org). I installed it via the daily PPA
and easily set up my 2 email accounts.

{% highlight bash %}
sudo add-apt-repository ppa:yorba/daily-builds
sudo apt-get update
sudo apt-get install geary california
{% endhighlight %}

## Calendar

Again, Evolution was too bloated and ugly, so I'm giving
[California](https://wiki.gnome.org/Apps/California) a whirl. It's fast, sleek,
and has natural language parsing like the quick add in Google Calendar.

It was simple to get it set up with a normal Gmail app, but in order to get it
working with my Google Apps acct for `jc00ke.com` I had to install Evolution. I
got that tip from [this bug
report](https://bugzilla.gnome.org/show_bug.cgi?id=740656). The crux is to leave
Evolution alone once set up. If you remove it, your Google Apps integration with
California will also disappear. I'm sure it'll get fixed soon.

## Outro

So far I'm enjoying the speed and minimal system resources by switching to
Pidgin, Geary and California. The native notifications have been missed too!

![notify-send
example](/assets/posts/going-native-pidgin-geary-and-california/notification-example.png)
