---
title: "Shortest URLs on the Internet"
date: 2022-08-29T19:00:20+01:00
---

What's the shortest URL for which content is served on the internet? There are
[quite a few](https://en.wikipedia.org/wiki/Single-letter_second-level_domain)
single-letter second-level domains that are used in very short URLs, such
as Google's <http://g.co> or Facebook's <https://m.me>.

Many organisations use even shorter URLs internally. For example, Google's
internal URL shortener uses URLs like `https://go/<id>` (Google's internal
nameservers point the `go` name at their URL shortening service).

In theory, there's nothing stopping TLD registries setting up their
external-facing nameservers to serve records like this too: if Verisign wished,
they could include an A record in the apex of the `com` TLD zone with an IP of a
web server. Visiting `https://com` would then take you to that web server.

Does any registry actually do this though? Surprisingly, the answer is yes.

---

First, let's find a list of TLDs which have A records.

```
$ wget https://data.iana.org/TLD/tlds-alpha-by-domain.txt
$ <tlds-alpha-by-domain.txt tail -n+2 | xargs -I{} ./get_a_record_tsv.sh {} > tld-a-records.tsv
```

where `get_a_record_tsv.sh` is:

```bash
#!/usr/bin/env bash
set -euo pipefail

name="$1"
records=$(dig +short @8.8.8.8 "$name" | head -n1)

echo -e "${name}\t${records}"
```

Now, let's get the TLDs that have A records:

```
$ <tld-a-records.tsv grep -Ev $'\t$'
AI	209.59.119.34
ARAB	127.0.53.53
CM	195.24.205.60
IN	e.root-servers.net.
KIDS	127.0.53.53
MD	e.root-servers.net.
MG	a.root-servers.net.
MR	m.root-servers.net.
MUSIC	127.0.53.53
MX	a.root-servers.net.
PN	139.162.17.173
TK	217.119.57.22
UZ	91.212.89.8
WS	64.70.19.33
XN--L1ACC	218.100.84.27
XN--MXTQ1M	127.0.53.53
XN--NGBRX	127.0.53.53
```

There's a bunch that have A records pointing at `127.0.53.53` (which is
an internal IP): [arab](https://icannwiki.org/.arab),
[عرب](https://icannwiki.org/.%D8%B9%D8%B1%D8%A8) (translates to "arab"),
[kids](https://icannwiki.org/.kids), [music](https://icannwiki.org/.music), and
[政府](https://icannwiki.org/.%E6%94%BF%E5%BA%9C) (translates to "government").
It turns out this is a [special IP
address](https://www.icann.org/resources/pages/name-collision-2013-12-06-en)
designed to alert network adminstrators of _name collisions_: cases where
networks have privately been using names underneath TLDs which used to be free,
but have now been allocated as gTLDs. The `53.53` is a reference to port 53, the
port used for the DNS.

Another strange set of entries are the ones with A records pointing to the root
servers. I'm not sure why this is - I think it might be because no DNS has been
configured in the TLD zone for these TLDs.

Filtering out the TLDs mentioned above, we get:

```
AI	209.59.119.34
CM	195.24.205.60
PN	139.162.17.173
TK	217.119.57.22
UZ	91.212.89.8
WS	64.70.19.33
XN--L1ACC	218.100.84.27
```

These are, in turn, the ccTLDs for [Anguilla](https://en.wikipedia.org/wiki/Anguilla),
[Cameroon](https://en.wikipedia.org/wiki/Cameroon),
[the Pitcairn Islands](https://en.wikipedia.org/wiki/Pitcairn_Islands),
[Tokelau](https://en.wikipedia.org/wiki/Tokelau),
[Uzbekistan](https://en.wikipedia.org/wiki/Uzbekistan),
[Samoa](https://en.wikipedia.org/wiki/Samoa) and
[Mongolia](https://en.wikipedia.org/wiki/Mongolia) (the TLD is an [internationalised
ccTLD](https://icannwiki.org/Internationalized_Domain_Name) in this case).

---

Let's open up the TLDs we found in a browser and see what happens:

```
$ <tld-a-records.tsv cut -f1 | xargs -I{} xdg-open 'http://{}'
$ <tld-a-records.tsv cut -f1 | xargs -I{} xdg-open 'https://{}'
```

Some of them do indeed load:

- [http://ai](http://ai) is a nice retro landing page for "Offshore Information
  Services", who [seem to maintain the .ai TLD](https://icannwiki.org/.ai)
- [http://pn](http://pn) serves an "it works" page; [https://pn](https://pn) serves "hello world" (with an invalid certificate)
- <https://uz> serves a HTTP 500; [https://uz](https://uz/) serves the
  Uzbekistan ccTLD's homepage (with an invalid certificate)
- <http://мон> eventually serves a blank page, but does also serve a
  [favicon](http://xn--l1acc/favicon.ico); <https://мон> eventually serves a
  default Apache landing page (with an invalid certificate)

{{< figure src="/images/anguilla.png" alt="Screenshot of http://ai" caption="Screenshot of http://ai" >}}

The others either time out or refuse the connection.

---

I'll finish by mentioning that [the use of dotless domains is discouraged by
ICANN](https://www.icann.org/news/announcement-2013-08-30-en):

> *Recommendation*: Dotless domains will not be universally reachable and the
> SSAC recommends strongly against their use. As a result, the SSAC also
> recommends that the use of DNS resource records such as A, AAAA, and MX in the
> apex of a TopLevel Domain (TLD) be contractually prohibited where appropriate
> and strongly discouraged in all cases.

And, furthermore, [the use of dotless domains is prohibited for new
gTLDs](https://www.icann.org/en/announcements/details/new-gtld-dotless-domain-names-prohibited-30-8-2013-en).