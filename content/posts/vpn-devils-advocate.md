---
title: "Playing devil's advocate on claims made in VPN adverts"
date: 2023-22-04:00:20+01:00
---

As a Gen-Z-er (just about), I spend too much time watching YouTube videos. This means I'm exposed to many adverts and video sponsorships from VPN companies (NordVPN in particular).

In many of these adverts, the supposed privacy and security benefits of using some VPN provider or another are proclaimed. (In fairness to VPN companies, they do seem to be shifting focus away from these kinds of claims in their advertising, but I still see it plenty).

Other people have also written and spoken about this topic, and have explained well why these claims are (mostly) bogus. One of the best examples I've seen of this is Tom Scott's ["This Video is Sponsored By ███ VPN"](https://www.youtube.com/watch?v=WVDQEoe6ZWY), published in 2019. This video is also great because it's accessible to a non-technical audience.

{{< youtube WVDQEoe6ZWY >}}

I agree with Tom's overall conclusion that using a VPN usually isn't beneficial for security or privacy nowadays, even when on a public WiFi network. In particular, I agree with his points that:

* "military grade encryption" is rubbish
* VPNs **do** stop your ISPs seeing your DNS traffic, but really you're just shifting that trust to your VPN provider instead

However, at the start of the video Tom makes another claim: he claims that, in the context of a MITM attacker, a VPN gives you no protection beyond that which HTTPS gives you.

With my devil's advocate hat on, I'm not sure I can fully agree with that point. Why not? SSL stripping.

---

## SSL stripping

In order to answer why I think VPNs do offer _some_ protection (however small) against MITM attackers, let us turn back time to 2009, to Moxie Marlinspike's Black Hat talk on SSL stripping.

You can read the slides from that talk [here](https://www.blackhat.com/presentations/bh-dc-09/Marlinspike/BlackHat-DC-09-Marlinspike-Defeating-SSL.pdf), and I'd encourage you to do so -- the slides contain a lot of interesting details, including a discussion about the earlier SSL sniffing attack, and a discussion on IDN homograph attacks. There are also some very nostalgic browser screenshots.

{{< figure src="/images/ssl-stripping-moxie.png" alt="Excerpt from Moxie's Black Hat slides" caption="Excerpt from Moxie's Black Hat slides" >}}

I'll demonstrate the SSL stripping attack through an example.

To set the scene, Alice has received a letter from her bank, and is connected to a public WiFi network. Bob is in control of that network, and is MITM'ing Alice's traffic. Bob's goal is to access Alice's account and drain its funds.

* Alice types the URL of her bank printed on the letter (your-bank.com)
* Alice's browser connects to http://your-bank.com
   * (Keen readers might be shouting "HSTS" at their screens at this point -- I will discuss that later, bear with me for now.)
* Bob intercepts that traffic (which is in plaintext)

Bob now has two options.

The first option is keeping Alice on http://your-bank.com, continuing intercepting her traffic, forwarding it to the real bank site behind the scenes, and capturing her credentials when she tries to login. Nowadays, browsers will present obvious visual cues that the connection is insecure, so Alice is unlikely to enter her credentials on this site. We can discount this option.

{{< figure src="/images/http-visual-cue.png" alt="Chrome's visual cue warning users about insecure connections" caption="Example of a visual cue that Chrome uses to warn users when they're on an insecure connection" >}}

The second (and better) option is to redirect Alice to a legitimate-looking domain that Bob controls. For example, he could redirect Alice to https://your-bank.online-payment-portal.com, or https://your-bank-retail.com, or something else even more devious -- the possibilities are endless. (Back in the day, you could use an IDN homograph attack here, but browsers are pretty good at protecting users from those these days).

This approach will allow Bob to serve Alice the site over HTTPS, meaning Alice will get the reassuring padlock in her browser. Assuming Alice doesn't get spooked by the URL being different, she'll enter her credentials, and Bob wins.

A keen-eyed user might spot a suspicious-looking URL, but many other users will not.

(As an aside, many organisations add to this problem by training users to accept entering their credentials on weird-looking URLs. For some reason, in my experience, this seems a particular problem with local government/councils. As an example, if you want to pay your council tax online in Monmouthshire, you'll be directed to `www.civicaepay.co.uk`).

### How using a VPN changes this attack vector

If Alice was connected to any VPN worth its salt, Bob's SSL stripping attack would not have worked: Alice's traffic would be transported over an encrypted and authenticated connection and could not be intercepted by Bob.

Of course, the VPN company could perform an SSL stripping attack on Alice's traffic in the exact same way, if it wanted to. But you could argue that a VPN company is less likely to be compromised than a random public WiFi network.

### Mitigations against this attack

SSL stripping isn't quite as scary as it first seems.

First off, the attack is pretty complicated. Bob would probably have better luck sending email phish to users and getting them to visit his lookalike site that way.

Sites can also mitigate against SSL stripping attacks by using _HSTS_.

#### HTTP Strict Transport Security (HSTS)

[HTTP Strict Transport Security](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security) (HSTS) basically lets sites tell browsers "if you connect to this site again, make sure it's over HTTPS, and reject the connection otherwise".

That's a good security mechanism, but by itself it doesn't protect users if they have never visted the site before, and are connecting for the first time. To mitigate against that problem, sites can also request that their HSTS records be _preloaded_ into browsers.

You can see the HSTS preload list that Chrome uses [here](https://source.chromium.org/chromium/chromium/src/+/main:net/http/transport_security_state_static.json) -- Firefox also [uses that list as a basis for the list it uses](https://wiki.mozilla.org/SecurityEngineering/HTTP_Strict_Transport_Security_(HSTS)_Preload_List).

Adoption of HSTS [is reasonable](https://w3techs.com/technologies/details/ce-hsts), although HSTS preload adoption isn't great. I just checked the login pages of four major UK banks -- all of them used HSTS, but only one was covered by HSTS preload.

## So, does this all mean I should use a VPN?

Having considered all of the above, I still agree with Tom Scott that VPNs aren't really worth it on the modern internet. SSL stripping is a fairly complicated attack, and the mitigations are reasonably good. I'm more worried about the inherent security risks of using a VPN than I am about the risk of a SSL stripping succeeding attack against me.
