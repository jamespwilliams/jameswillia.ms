---
title: "Short Domain Names"
date: 2020-08-15T19:00:20+01:00
---

What's the shortest in-use domain name? There are [quite a
few](https://en.wikipedia.org/wiki/Single-letter_second-level_domain)
three-letter domain names being used, such as Google's g.co and Facebook's
m.me.

However, these aren't the shortest domain names in use. A TLD is a valid
domain name on its own, and there's nothing stopping registrars from
creating A records for their TLDs.
For example:

```
$ dig +short A ai
209.59.119.34
```

Here's a list of all TLDs which have A records and resolve to responsive servers
(as of August 2020):

- [ai](http://ai)
- [dk](http://dk) (redirects to www.dk-hostmaster.dk)
- [pn](http://pn)
- [uz](https://uz)
- [мон](http://мон) (just gives a blank page after loading for a while)

{{< hint info >}} **Note:**
Try
adding full stops after the domain names if your browser has issues opening them.  {{< /hint >}}

Now that Google has its own gTLD, there's nothing stopping them from
using [https://google](https://google) as the URL of their homepage. Well,
nothing other than some [strong
words](https://www.icann.org/news/announcement-2013-08-30-en) from the ICANN
Security and Stability Advisory Committee:

> *Recommendation*: Dotless domains will not be universally reachable and the
> SSAC recommends strongly against their use. As a result, the SSAC also
> recommends that the use of DNS resource records such as A, AAAA, and MX in the
> apex of a TopLevel Domain (TLD) be contractually prohibited where appropriate
> and **strongly discouraged in all cases**.

(emphasis mine).
