---
title: Setting up Cisco AnyConnect VPN on 64bit Xubuntu 14.04
layout: post
description: No Java needed
author: Jesse
tags:
- cisco
- vpn
---

A client of mine uses Cisco's AnyConnect VPN, and while it's pretty easy to get
set up on OS X and Windows, it was quite the headache to get it to work on
Ubuntu/Xubuntu. I tried adapting [Eugene's](http://j.mp/1snlbuE) method but
didn't have much luck. But with the latest version I could find (which you can
[download here](/assets/posts/cisco-anyconnect-on-64bit-xubuntu/anyconnect-predeploy-linux-64-3.1.05160-k9.tar.gz))
and some `iptables` magic I was able to connect.

My client's configuration requires a compatible firewall to be running, which
is why I had to uninstall `ufw` and install `iptables`.

{% highlight bash %}
$> wget http://jc00ke.com/assets/posts/cisco-anyconnect-on-64bit-xubuntu/anyconnect-predeploy-linux-64-3.1.05160-k9.tar.gz
$> tar xf anyconnect-predeploy-linux-64-3.1.05160-k9.tar.gz
$> cd anyconnect-3.1.05160/vpn
$> sudo ./vpn_install.sh
<accept terms>
$> cd ../posture
$> sudo ./posture_install
<accept terms>
$> sudo -i
$> apt-get remove ufw
$> iptables-save
$> iptables -nvL
$> iptables -A INPUT -i lo -j ACCEPT
$> iptables -A INPUT -i eth0 -m state --state ESTABLISHED -j ACCEPT
$> iptables -A INPUT -i wlan0 -m state --state RELATED -j ACCEPT
$> iptables -A INPUT -i eth0 -m state --state RELATED -j ACCEPT
$> iptables -A INPUT -i eth0 -p icmp --icmp-type echo-request -j ACCEPT
$> iptables -A INPUT -i wlan0 -p icmp --icmp-type echo-request -j ACCEPT
$> iptables -A INPUT -i eth0 -p tcp --syn --dport 22 -s 0.0.0.0/0 -j ACCEPT
$> iptables -A INPUT -i wlan0 -p tcp --syn --dport 22 -s 0.0.0.0/0 -j ACCEPT
$> iptables -P FORWARD DROP
$> iptables -P INPUT DROP
$> touch /etc/iptables
$> iptables-save > iptables
$> vim /etc/rc.local
<add the following above 'exit 0'>
# Added by <your name> when configuring iptables
/sbin/iptables-restore < /etc/iptables
<:wq to save and exit vim>
$> iptables-save > /etc/iptables
<review changes>
$> exit
{% endhighlight %}

Now when you fire up the Cisco AnyConnect client you'll (hopefully) be able to
connect without hours of hair pulling.
