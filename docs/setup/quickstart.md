---
title: "Snikket quick-start guide"
subtitle: "How to set up a self-hosted Snikket instance"
linktitle: "Quick-start"
description: "This guide will help you set up your self-hosted Snikket instance."
date: 2022-01-25T12:32:02Z
weight: 10
---

{{< lead >}}
Hi, welcome! In this guide we will help you set up your own instance of [Snikket](/service/). Once it is set up,
you will be able to invite others to join you using the [Snikket app](/app/) and chat over your own
private messaging server!
Right, let's get started...
{{< /lead >}}

## Requirements

To follow this guide you will need:

 - A server running Linux that you have SSH or terminal access to
 - A domain name that you can create subdomains on

For the server, you can use a VPS from a provider such as [DigitalOcean](https://digitalocean.com/) (you can use this [referral link for $100 credit](https://m.do.co/c/3ade5a32d0e0)),
or you can use a physical device such as a Raspberry Pi. Note that if you run your server at home (which is _really_ cool!) you may need to forward some ports on your
router.

If you don't have a domain name yet, see the FAQ ["Do I need to register a domain name to use Snikket?"](https://snikket.org/faq/#q-do-i-need-to-register-a-domain-name-to-use-snikket)
for some advice.

**Note:** Snikket provides a built-in web server that must be accessible on port 80. This guide assumes you are _not_ running any existing
websites on the same server. If you are running other HTTP services on the same server, refer to our [reverse proxy](../..//advanced/reverse_proxy/)
documentation after you complete step 3.

Finally, if you can't meet these requirements but want to use Snikket anyway, check out our [Snikket Hosting](https://snikket.org/hosting/) service which lets you set up Snikket with minimal technical knowledge and just a few clicks.

## Get Started

### Step 1: DNS

You need to set up DNS records so that the Snikket apps can look up and connect to your server.

{{< panel style="info">}}
**Hosting at home?**
If you plan to host your Snikket instance at home, check with your ISP whether you have a static or dynamic IP address on your home connection.
For advice on setting up Snikket with a dynamic IP, see ["Can I host Snikket if I have a dynamic IP address?"](https://snikket.org/faq/#q-can-i-host-snikket-if-i-have-a-dynamic-ip-address).
{{< /panel >}}

First you need to find your server's public ("external") IP address. If you are using a hosted server, this may be shown in your management dashboard.
At a pinch you can use an online service, e.g. by running `curl -4 ifconfig.co` in your terminal.

Now, add an A record for your IP address on the domain you want to run Snikket on. In the examples I'm going to use 'chat.example.com' as the domain,
and '203.0.113.123' as the IP address. This will be the primary domain for your Snikket instance.

```
# Domain           TTL  Class  Type  Target
chat.example.com.  300  IN     A     203.0.113.123
```

How to add records depends on where your DNS is hosted. Here are links to guides for a few common providers:

- [GoDaddy](https://uk.godaddy.com/help/add-an-a-record-19238)
- [Gandi](https://docs.gandi.net/en/domain_names/faq/record_types/a_record.html)
- [Namecheap](https://www.namecheap.com/support/knowledgebase/article.aspx/319/2237/how-can-i-set-up-an-a-address-record-for-my-domain)

**Tip:** If you have an IPv6 address too, this is where you can add it - simply make another record for `chat.example.com.` with the record
type `AAAA` and put your IPv6 address as the target.

Now that you have an A record, you also need a couple more records. To avoid repeating the IP address everywhere, we'll use CNAME records,
which are just like aliases of the main domain:

```
# Domain            TTL  Class  Type   Target
groups.chat.example.com  300  IN     CNAME  chat.example.com.
share.chat.example.com   300  IN     CNAME  chat.example.com.
```

These subdomains provide group chat functionality and file-sharing respectively.

{{< panel style="info">}}
**Check that firewall!**
If you're setting up Snikket at home, or behind a router or firewall, now is a good time to check that you have all the [required ports open
](../../advanced/firewall/) or forwarded. If you're using a VPS and there is no
firewall, you're fine... onto the next step!
{{< /panel >}}

### Step 2: Docker

Docker is a handy tool for running self-contained services known as "containers". We use Docker to provide Snikket
in a clean way that works reliably across all different systems.

If you have the `docker` and `docker compose` commands already available on your system, great! You can skip to Step 3 below. If not, continue reading.

#### docker

Getting docker up and running can vary depending on what OS you're running. Luckily Docker provides an installation guide
for a range of operating systems. Follow the guide for your system:

- [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/)
- [Debian](https://docs.docker.com/install/linux/docker-ce/debian/)
- [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/)
- [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

{{< panel style="warning" >}}
**Compatibility note**

Snikket is not compatible with the following host systems:

- Debian 10 (or Raspbian 10) "buster" running on Raspberry Pi or other ARM devices (upgrade your OS)
- Systems running Docker versions older than 20.10.10 (upgrade Docker using the guides linked above)

For more information, review the [host 
compatibility](https://snikket.org/service/help/setup/troubleshooting/#host-compatibility)
section of our documentation.
{{< /panel >}}

### Step 3: Prepare for Snikket!

This is exciting, we're so close!

Create a configuration directory and switch to it:

```bash
mkdir /etc/snikket
cd /etc/snikket
```

And then download our `docker-compose.yml` file:

```bash
curl -o docker-compose.yml https://snikket.org/service/resources/docker-compose.yml
```

Now create another file called `snikket.conf` in the same directory, using a text editor (such as nano, or vim).

This file is where your configuration goes. There are just a couple of options you need:

```bash
# The primary domain of your Snikket instance
SNIKKET_DOMAIN=chat.example.com

# An email address where the admin can be contacted
# (also used to register your Let's Encrypt account to obtain certificates)
SNIKKET_ADMIN_EMAIL=you@example.com
```

Change the values to match your setup, save the file, and exit.

{{< panel style="info">}}
**Do you need to reverse proxy?**

Earlier we mentioned that Snikket needs access to the HTTP+HTTPS ports on the server. If you already
have websites or other web services on the server where you are installing Snikket, **now is
the time to configure your reverse proxy** to share web traffic with your Snikket instance.
Luckily we have you covered with our little [reverse proxy guide](../../advanced/reverse_proxy/),
which includes example configuration for a range of web servers and proxy software.

When you're done, come back here and continue with the final launch step!
{{< /panel >}}

### Step 4: Launch

Here we go! Run:

```bash
docker compose up -d
```

The first time you run this command docker will download Snikket. In a moment it should complete,
and Snikket should be running and accessible via the web (e.g. `http://chat.example.com/`). As
soon as it has created certificates, it will redirect to HTTPS and show you a login page.

{{< panel style="secondary" >}}
**Note:** If this command returns an error like `"compose" is not a docker command`, don't panic!
You just need to [install the docker compose plugin](https://docs.docker.com/compose/install/linux/#install-using-the-repository)
and try again.
{{< /panel >}}

Now Snikket is running, it's time to set up your first account. To create yourself an admin account, run the following command:

```bash
docker exec snikket create-invite --admin --group default
```

Follow the link to open the invitation, and follow the instructions get signed in.

Once you've created your admin account, you can log in to the web dashboard
by visiting `https://chat.example.com/` in your browser (obviously put your own
domain in there!).

From there you can create more invitation links to share with your family, friends
and anyone else you want to join your Snikket instance. It won't be empty for long!

{{< panel style="success" >}}
That's it! How did it go? Let us know at feedback@snikket.org. Also if you want to support
the project, consider a small [donation](/donate/) to help keep us working on it!
{{< /panel >}}
