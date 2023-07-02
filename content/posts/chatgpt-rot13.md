---
title: "ChatGPT vs rot13"
date: 2022-12-05:00:20+01:00
---

I thought it would be interesting to see whether ChatGPT could solve some basic ciphers (Caesar, Vignere, etc.). I decided to start at the bottom, with perhaps the easiest possible cipher: [rot13](https://en.wikipedia.org/wiki/ROT13). I asked it to decode the rot-13 encoding of "Why did the chicken cross the road":

{{< figure src="/images/chatgpt-rot13.png" link="/images/chatgpt-rot13.png" >}}

So the first thing to note here is that ChatGPT is not able to solve the task, even for very small cases.

But nonetheless, I found this exchange interesting. ChatGPT's approach to solving this brought to mind Daniel Kahneman's book [Thinking, Fast and Slow](https://en.wikipedia.org/wiki/Thinking,_Fast_and_Slow). To me, it feels like ChatGPT is attempting to apply System 1 thinking (fast, instinctual) to a problem that requires a System 2 approach, and ends up getting exactly the results you'd expect from that: answers that looks vaguely sensible, but are actually way off base.

As a human, when performing rot13 decoding, you apply System 2 thinking: working through each letter, doing calculations in your head to find the right letter -- perhaps remembering common letter mappings as you go. But in this case, it feels like ChatGPT is approaching the problem like a language learner put on spot: going wordwise, hazily recognising words, and filling in the gaps from there.

I wonder whether the distinction between the tasks ChatGPT is good at, and those that it isn't, is whether the task is more amenable to System 1 or System 2 thinking? When I think of things that ChatGPT has been observed to be poor at, for example:

* evaluating complex mathematical equations
* writing mathematical proofs
* solving cryptic crossword clues

all of them (generally) require some degree of System 2 thinking as a human. On the other hand, many of the tasks it is good at are things that humans use System 1 thinking to do:

* translating languages (once fluent)
* writing jokes
* summarising text

When it makes mistakes, ChatGPT also displays the kind of overconfidence that System 1 thinking results in.

Interestingly, ChatGPT can kind of follow along with our System 2 reasoning (e.g: where I explained that it answering plaintext with a different number of letters from the ciphertext could not make sense, because rot13 is a one-to-one mapping). But it seems incapable of taking that reasoning and applying it again, even when the next application is very similar.
