---
title: "Setting up Pi-hole with both Wi-Fi AP AND ethernet sharing"
date: 2019-12-19
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

This short note is actually a follow-up of [this previous post](https://akitaki.gitlab.io/pihole-ap/). Instead of making a single WiFi access point, I wanted it to additionally share Internet access using another USB-to-RJ45 adapter (since the built-in ethernet port is already used to hook the pi up with the internet). After looking up on the net for a while, I found that it's relatively simple.

Suppose that you already have the WiFi hotspot from the previous note working, then there aren't much to change. First of all, we need to find out the interface name of the ethernet adapter. This can be trivially done with the `ifconfig` command.

```bash
(ssh) akitaki@xbpi : ~
[0] % ifconfig | grep '^[^ ]*:'
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
```

<!-- more -->

Okay, so in my case, the name of the new interface is `eth1`. We then proceed to prevent this device from being controlled by the DHCP client.

```bash
echo denyinterfaces eth1 | sudo tee -a /etc/dhcpd.conf
```

Then, make adjustments to IPTables. In this part, `eth0` and `eth1` are the source and destination interface, respectively.

```bash
# Setup rules
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
# Write to disk
sudo bash -c "iptables-save > /etc/iptables.ipv4.nat"
```

We need to setup the built-in DHCP server that comes with Pi-hole such that there are two gateways, one for WiFi AP and the other for ethernet sharing. A quick search shows that [shows that this is absolutely doable with dnsmasq](https://stackoverflow.com/questions/29453522/how-to-specify-two-or-more-gateways-in-dnsmasq) using the optional `set:<tag>` syntax which lets us to specify labels on a per-network basis. Since there isn't integrated support for this in the web admin page provided by Pi-hole, we must manually edit the underlying config file. Change the contents of `/etc/dnsmasq.d/02-pihole-dhcp.conf` to something like the following:

```
###############################################################################
#  DHCP SERVER CONFIG FILE AUTOMATICALLY POPULATED BY PI-HOLE WEB INTERFACE.  #
#            ANY CHANGES MADE TO THIS FILE WILL BE LOST ON CHANGE             #
###############################################################################
dhcp-authoritative
dhcp-range=set:tag0,192.168.42.201,192.168.42.251,24h
dhcp-range=set:tag1,192.168.52.201,192.168.52.251,24h
dhcp-option=tag:tag0,option:router,192.168.42.1
dhcp-option=tag:tag1,option:router,192.168.52.1
dhcp-leasefile=/etc/pihole/dhcp.leases
#quiet-dhcp

domain=lan
```

In this example, we're assigning `192.168.42.~` and `192.168.52.~` to clients connecting from WiFi AP and ethernet, respectively. Notice that this file may be overwritten by Pi-hole again if you fiddle with the admin panel, so you'd like to make a backup of this file in case it's lost.

Also add a new systemd network configuration for `eth1` to reflex this change.

```ini
# /etc/systemd/network/eth1.network
[Match]
Name=eth1

[Network]
Address=192.168.52.1/24
IPForward=ipv4
```

After a reboot, all things should be working fine now.
