---
title: "ChatGPT vs a cryptic crossword"
date: 2022-12-05:00:20+01:00
---

{{< figure src="/images/crossword.jpg" alt="The first Times crossword" caption="The first Times crossword" >}}

Having seen several mind-blowing articles about ChatGPT's ability (most notably [this one](https://www.engraved.blog/building-a-virtual-machine-inside/)), I wondered how ChatGPT would fare solving a [cryptic crossword](https://en.wikipedia.org/wiki/Cryptic_crossword).

I decided to try with an easy one: a Quick Cryptic from The Times. I had a search through [the Times for the Times archives](https://timesforthetimes.co.uk/category/quick-cryptic) to try and find one on the easier side. Eventually, I settled on [Quick Cryptic 2273 by Beck](https://timesforthetimes.co.uk/times-quick-cryptic-no-2273-by-beck), which was described as "very gentle" by the solver.

---

Okay, let's get started:

{{< figure src="/images/chatgpt-cryptic1.png" >}}

A swing... and a miss. Wrong answer, and the reasoning is nonsensical.

(The answer is "MANTRA" -- MAN (chap) and ART (skill) reversed (recalled)).

---

Let's hit "try again":

{{< figure src="/images/chatgpt-cryptic2.png" >}}

Correct answer! But let's check the reasoning...

Chap is indeed [derived from chapman](https://en.wiktionary.org/wiki/chap#Etymology_1) (which was news to me), and a chapman _is_ a trader.

But that's where we start to go off the rails... TRADER reversed is REDART, not REDARAT. And REDARAT is definitely not a homophone of MANTRA.

---

One more try:

{{< figure src="/images/chatgpt-cryptic3.png" >}}

Okay -- again, the right answer! How is it getting to the answer though?

> taking the first letter of the word "chap" (M)

uhhh...

> the past tense of the verb "to recall" (ANT)

umm...

> and the first two letters of the word "skill" (RA)

???

--- 

Okay, let's try another clue.

{{< figure src="/images/chatgpt-cryptic4.png" >}}

The solution here is IMPACT – ACT (legislation) after I (one) and MP (politician) ("Introduced by" is an indicator to put the I MP at the front.)

---

Maybe the clues I've been trying have been too hard. Let's try the easiest one I can find.

{{< figure src="/images/chatgpt-cryptic5.png" >}}

So close, yet so far... The reasoning is _almost_ right. The correct reasoning is S + US (American) + HI (greeting).

---

### Conclusion

Credit where it's due, ChatGPT gets a couple of things right in these tests:

* it understands the structure of a clue in most case: it gets that the clue is formed of a straight and cryptic part, and the straight part is at the start or end
* it generally answers with the correct amount of letters
* it understands what wordplay is (anagrams, homophones, reversal, concatenation, etc.), and kind of applies them -- just incorrectly

And, importantly, it occasionally gets to the correct answer. But in these cases, it appears to reach the correct answer entirely based on the straight clue: it forces the cryptic solution backwards from there (even when it makes no sense).

I find it interesting that it replies with 100% confidence, despite the reasoning being obviously (to a human) absurd.

I guess cryptic crosswords fall into the (surprisingly small) category of things that ChatGPT just isn't very good at!
