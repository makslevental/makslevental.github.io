---
layout: post
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: Confidence intervals
tags: [statistics]
---

Suppose $$x_{1},x_{2},\dots,x_{n}$$ are all quantities drawn, without
replacement, a “random” sample, from some population, the same
population, which itself has an $$\mathcal{N}\left(\mu,\sigma^{2}\right)$$
distribution. If the population size is large enough it’s safe to make
the approximation that each draw does not affect the population
distribution (despite non-replacement) and so effectively each of the
$$x_{i}$$ is a draw from an $$\mathcal{N}\left(\mu,\sigma^{2}\right)$$
distribution, i.e. each $$x_{i}$$ is actually the random variable
$$X_{i}\sim\mathcal{N}\left(\mu,\sigma^{2}\right)$$. What can we say about
the distribution of the random variable
$$\bar{X}\equiv\frac{1}{n}\sum_{i=1}^{n}X_{i}$$, i.e. the distribution of
the “sample mean”? Furthermore what can we say about the distribution of
the sample variance
$$S^{2}\equiv\frac{1}{n-1}\sum_{i=1}^{n}\left(X_{i}-\bar{X}\right)^{2}$$?

<!--more-->

**Theorem 1.**
1. $\bar{X}\sim\mathcal{N}\left(\mu,\sigma^{2}/n\right)$
2. $\bar{X}$ and $S^{2}$ are independent.
3. $\frac{\left(n-1\right)}{\sigma^{2}}S^{2}\sim\chi_{n-1}^{2}$

What does this really say? It says that $$\bar{X}$$ is distributed with
the same distribution and the **same mean as the population** **you drew
from** and that its variance is inversely proportional to the variance
of the population by a factor equal to the sample size. That is to say,
if we could somehow figure out the mean of $$\bar{X}$$, we would then
immediately know the mean of the population. Of course we can’t
(philosophically speaking) but we’ll do something else involving the
mean that’ll be almost as useful.

**Proof I.** First we prove that the
$$\bar{X}\sim\mathcal{N}\left(\mu,\sigma^{2}/n\right)$$: the MGF of
$$X_{i}$$

$$MGF_{X_{I}}(t)=e^{\mu t+\frac{1}{2}\sigma^{2}t^{2}}$$

and therefore by the convolution theorem

$$MGF_{X_{1}+\cdots+X_{n}}(t)=\left(e^{\mu t+\frac{1}{2}\sigma^{2}t^{2}}\right)^{n}=e^{\left(\mu n\right)t+\frac{1}{2}\left(\sqrt{n}\sigma\right)^{2}t^{2}}$$

Hence $$\sum X_{i}\sim\mathcal{N}\left(n\mu,n\sigma^{2}\right)$$. Then
since the normal distribution is a scale family
$$(1/n)\sum X_{i}\sim\mathcal{N}\left(\frac{1}{n}n\mu,\left(\frac{1}{n}\right)^{2}n\sigma^{2}\right)\sim\mathcal{N}\left(\mu,\sigma^{2}/n\right)$$.

■

Let’s stop here for a moment see what just this alone buys us. Suppose
you had some population for which you knew the variance $$\sigma^{2}$$ but
you didn’t know the mean (absurd but suspend disbelief): could you make
a guess of the mean and then qualify your guess? Well since we know that
$$\bar{X}\sim\mathcal{N}\left(\mu,\sigma^{2}/n\right)$$ we know, by
“standardizing” $$\bar{X}$$, that

$$P\left(-1.96<\frac{\bar{X}-\mu}{\grave{\sqrt{\sigma^{2}/n}}}<1.96\right)\geq.95$$

After a little algebra (and flipping two inequalities) we have that

$$P\left(\bar{X}-1.96\sqrt{\frac{\sigma^{2}}{n}}<\mu<\bar{X}+1.96\sqrt{\frac{\sigma^{2}}{n}}\right)\geq.95$$

So with probability .95 if we measure $$\bar{X}$$ the interval

$$\left(\bar{X}-1.96\sqrt{\frac{\sigma^{2}}{n}},\bar{X}+1.96\sqrt{\frac{\sigma^{2}}{n}}\right)$$

will cover the true mean of the population (remember we said we somehow
knew $$\sigma^{2}$$ and $$n$$ is just the sample size). For this reason this
is called a 95% confidence interval for $$\mu$$. This is also called
computing a “z test statistic” since a standard normal random variable
is typically represented by a $$Z$$.
Back to the proof of theorem.

**Proof II.** Note that by location-scale it suffices to prove
$$\bar{X}\sim\mathcal{N}\left(\mu,\sigma^{2}/n\right)$$ for $$\mu=0$$ and
$$\sigma^{2}=0$$. To prove independence of $$\bar{X}$$ and $$S^{2}$$ we show
that they’re functions of independent random vectors. First we write
$$S^{2}$$ in terms of $$n-1$$ “deviations”

$$\begin{align}
S^{2} & =\frac{1}{n-1}\sum_{i=1}^{n}\left(X_{i}-\bar{X}\right)^{2}\\
 & =\frac{1}{n-1}\left(\left(X_{1}-\bar{X}\right)^{2}+\sum_{i=2}^{n}\left(X_{i}-\bar{X}\right)^{2}\right)\\
 & =\frac{1}{n-1}\left(\left[\sum_{i=2}^{n}\left(X_{i}-\bar{X}\right)\right]^{2}+\sum_{i=2}^{n}\left(X_{i}-\bar{X}\right)^{2}\right)\end{align}$$

Now solve for the quantity $$\left(X_{1}-\bar{X}\right)$$ using
$$\sum_{i=1}^{n}\left(X_{i}-\bar{X}\right)=0$$ and factor out a $$-1$$
(which gets killed in the $$\left[\right]^{2}$$).

$$S^{2}=\frac{1}{n-1}\left(\left[\sum_{i=2}^{n}\left(X_{i}-\bar{X}\right)\right]^{2}+\sum_{i=2}^{n}\left(X_{i}-\bar{X}\right)^{2}\right)$$

So
$$S^{2}=g\left(\left(X_{2}-\bar{X},X_{3}-\bar{X},\dots,X_{n}-\bar{X}\right)\right)$$
where $$g$$ is clearly continuous. Now we show that the random vector
$$\left(X_{2}-\bar{X},X_{3}-\bar{X},\dots,X_{n}-\bar{X}\right)$$ is
independent of $$\bar{X}$$, and by continuity $$S^{2}$$ will be independent
of $$\bar{X}$$. The joint pdf of $$\left(X_{1},X_{2},\dots,X_{n}\right)$$ is

$$\begin{align}
f_{X}\left(x_{1},\dots,x_{n}\right) & =\prod_{i=1}^{n}\frac{1}{\sqrt{2\pi}}e^{-\frac{1}{2}x_{i}^{2}}\\
 & =\left(\frac{1}{\sqrt{2\pi}}\right)^{n}e^{-\frac{1}{2}\sum_{i=1}^{n}x_{i}^{2}}\end{align}$$

Now let

$$\begin{pmatrix}1/n &1/n & \cdots 1/n\\
-1/n &1-1/n & -1/n -1/n\\
\vdots &-1/n & \ddots -1/n\\
-1/n &-1/n & -1/n 1-1/n
\end{pmatrix}\begin{pmatrix}x_{1}\\
x_{2}\\
\vdots\\
x_{n}
\end{pmatrix}=\begin{pmatrix}y_{1}\\
y_{2}\\
\vdots\\
y_{n}
\end{pmatrix}$$

i.e.

$$\begin{align}
y_{1} & =\bar{x}=\frac{1}{n}x_{1}+\frac{1}{n}x_{2}+\cdots+\frac{1}{n}x_{n}\\
y_{2} & =x_{2}-\bar{x}\\
\vdots &\quad\quad\vdots\\
y_{n} & =x_{n}-\bar{x}\end{align}$$

and therefore solve the first equation for $$x_{1}$$ in terms of the
$$y_{i}$$ by substituting in $$x_{2},x_{3},\dots,x_{n}$$

$$\begin{pmatrix}1 &-1 & \cdots & -1\\
1 &1 & 0 & 0\\
\vdots &0 & \ddots & 0\\
1 &0 & 0 & 1
\end{pmatrix}\begin{pmatrix}y_{1}\\
y_{2}\\
\vdots\\
y_{n}
\end{pmatrix}=\begin{pmatrix}x_{1}\\
x_{2}\\
\vdots\\
x_{n}
\end{pmatrix}$$

Then the Jacobian of the transformation

$$\left|J\right|=\left|\begin{pmatrix}1 &-1 & \cdots & -1\\
1 &1 & 0 &0\\
\vdots &0 & \ddots& 0\\
1 &0 & 0& 1
\end{pmatrix}\right|=\left|\begin{pmatrix}n &0 & \cdots& 0\\
1 &1 & 0& 0\\
\vdots &0 & \ddots& 0\\
1 &0 & 0& 1
\end{pmatrix}\right|=n$$

using the invariance of the determinant under linear combinations of
rows. Hence

$$\begin{align}
f_{Y}\left(y_{1},\dots,y_{n}\right) & =f_{X}\left(y_{1}-\sum_{i=2}^{n}y_{i},y_{1}+y_{2}\dots,y_{1}+y_{n}\right)n\\
 & =\left(\frac{1}{\sqrt{2\pi}}\right)^{n}e^{-\frac{1}{2}\left(\left(y_{1}-\sum_{i=2}^{n}y_{i}\right)^{2}+\sum_{i=2}^{n}\left(y_{1}+y_{i}\right)^{2}\right)}\\
 & =\left(\frac{1}{\sqrt{2\pi}}\right)^{n}e^{-\frac{1}{2}\left(y_{1}^{2}-2y_{1}\sum_{i=2}^{n}y_{i}+\left(\sum_{i=2}^{n}y_{i}\right)^{2}+\sum_{i=2}^{n}y_{1}^{2}+2y_{1}\sum_{i=2}^{n}y_{i}+\sum_{i=2}^{n}y_{i}^{2}\right)}\\
 & =\left(\frac{1}{\sqrt{2\pi}}\right)^{n}e^{-\frac{1}{2}\left(y_{1}^{2}+\sum_{i=2}^{n}y_{1}^{2}+\sum_{i=2}^{n}y_{i}^{2}+\left(\sum_{i=2}^{n}y_{i}\right)^{2}\right)}\\
 & =\left(\left(\frac{1}{\sqrt{2\pi}}\right)^{n}e^{-\frac{1}{2}ny_{1}^{2}}\right)\left(e^{-\frac{1}{2}\left(\sum_{i=2}^{n}y_{i}^{2}+\left(\sum_{i=2}^{n}y_{i}\right)^{2}\right)}\right)\end{align}$$

and so $$Y_{1}\equiv\bar{X}$$ is independent of
$$\left(Y_{2},Y_{3},\dots,Y_{n}\right)\equiv\left(X_{2}-\bar{X},X_{3}-\bar{X},\dots,X_{n}-\bar{X}\right)$$
and so $$\bar{X}$$ is independent of
$$S^{2}=g\left(\left(X_{2}-\bar{X},X_{3}-\bar{X},\dots,X_{n}-\bar{X}\right)\right)$$.

■

This is kind of amazing in and of itself, that
$$S^{2}=h\left(\bar{X}\right)$$ is statistically speaking independent of
$$\bar{X}$$ but it’s also useful and why will be apparent after the
completion of the proof, i.e. establishing that
$$\frac{\left(n-1\right)}{\sigma^{2}}S^{2}\sim\chi_{n-1}^{2}$$.

**Proof III.** There are two ways to do this. First

$$\begin{align}
\sum_{i=1}^{n}\left(X_{i}\right)^{2} & =\sum_{i=1}^{n}\left(\left(X_{i}-\bar{X}\right)+\bar{X}\right)^{2}\\
 & =\sum_{i=1}^{n}\left(X_{i}-\bar{X}\right)^{2}+2\left(\bar{X}\right)^{2}\cancelto{0}{\sum_{i=1}^{n}\left(X_{i}-\bar{X}\right)}+\sum_{i=1}^{n}\left(\bar{X}\right)^{2}\\
 & =\sum_{i=1}^{n}\left(X_{i}-\bar{X}\right)^{2}+\sum_{i=1}^{n}\left(\bar{X}\right)^{2}\\
 & =\left(n-1\right)S^{2}+n\left(\bar{X}\right)^{2}\end{align}$$

and by almost exactly the same manipulation (the “cross” term will be a
little different but it’s irrelevant since it goes to 0)

$$\sum_{i=1}^{n}\left(X_{i}-\mu\right)^{2}=\left(n-1\right)S^{2}+n\left(\bar{X}-\mu\right)^{2}$$

but then

$$\begin{align}
\sum_{i=1}^{n}\left(\frac{X_{i}-\mu}{\sigma}\right)^{2} & =\frac{1}{\sigma^{2}}\left(\left(n-1\right)S^{2}+n\left(\bar{X}-\mu\right)^{2}\right)\\
 & =\frac{\left(n-1\right)}{\sigma^{2}}S^{2}+\left(\frac{\bar{X}-\mu}{\sigma/\sqrt{n}}\right)^{2}\end{align}$$

Now again by convolution theorem and independence of $$S^{2}$$ and
$$\bar{X}$$ we have

$$\begin{align}
MGF_{\sum_{i=1}^{n}\left(\frac{X_{i}-\mu}{\sigma}\right)^{2}} & =MGF_{\frac{\left(n-1\right)}{\sigma^{2}}S^{2}}MGF_{\left(\frac{\bar{X}-\mu}{\sigma/\sqrt{n}}\right)^{2}}\end{align}$$

But
$$\sum_{i=1}^{n}\left(\frac{X_{i}-\mu}{\sigma}\right)^{2}\sim\chi_{n-1}^{2}$$
and
$$\left(\frac{\bar{X}-\mu}{\sigma/\sqrt{n}}\right)^{2}\sim\chi_{1}^{2}$$
so

$$\begin{align}
\left(\frac{1}{1-2t}\right)^{n/2} & =MGF_{\frac{\left(n-1\right)}{\sigma^{2}}S^{2}}\left(\frac{1}{1-2t}\right)^{1/2}\end{align}$$

and so

$$\begin{align}
MGF_{\frac{\left(n-1\right)}{\sigma^{2}}S^{2}} & =\left(\frac{1}{1-2t}\right)^{n/2}\Bigg/\left(\frac{1}{1-2t}\right)^{1/2}\\
 & =\left(\frac{1}{1-2t}\right)^{\frac{n-1}{2}}\end{align}$$

and hence $$\frac{\left(n-1\right)}{\sigma^{2}}S^{2}\sim\chi_{n-1}^{2}$$.
But doesn’t this directly imply that
$$\sum_{i=1}^{n}\left(\frac{X_{i}-\mu}{\sigma}\right)^{2}$$ and
$$n\left(\frac{\bar{X}-\mu}{\sigma/\sqrt{n}}\right)^{2}$$ doesn’t it?

$$\begin{align}
\frac{\left(n-1\right)}{\sigma^{2}}S^{2} & =\frac{1}{\sigma^{2}}\left(\sum_{i=1}^{n}\left(\frac{X_{i}-\mu}{\sigma}\right)^{2}-\left(\frac{\bar{X}-\mu}{\sigma/\sqrt{n}}\right)^{2}\right)\\
 & =\sum_{i=1}^{n}\left(\frac{X_{i}-\mu}{\sigma}\right)^{2}-n\left(\frac{\bar{X}-\mu}{\sigma/\sqrt{n}}\right)^{2}\end{align}$$

The second way is to use induction with $$\bar{X_{k}}$$ and $$S_{k}^{2}$$
being the sample mean and variance for a sample of size $$k$$. The base
case

$$\begin{align}
S_{2}^{2} & =\frac{1}{2-1}\left(\left(X_{1}-\frac{1}{2}\left(X_{1}+X_{2}\right)\right)^{2}+\left(X_{2}-\frac{1}{2}\left(X_{1}+X_{2}\right)\right)^{2}\right)\\
 & =\frac{1}{2}\left(X_{1}-X_{2}\right)^{2}\end{align}$$

and if $$X_{1}\sim X_{2}\sim\mathcal{N}\left(\mu,\sigma^{2}\right)$$ then
$$X_{1}-X_{2}\sim\mathcal{N}\left(0,2\sigma^{2}\right)$$ and
$$X_{1}-X_{2}/\left(\sqrt{2}\sigma\right)\sim\mathcal{N}\left(0,1\right)$$
so

$$\begin{align}
\frac{\left(2-1\right)}{\sigma^{2}}S_{2}^{2} & =\frac{1}{2\sigma^{2}}\left(X_{1}-X_{2}\right)^{2}\\
 & =\left(\frac{X_{1}-X_{2}}{\sqrt{2}\sigma}\right)^{2}\end{align}$$

hence $$\frac{\left(2-1\right)}{\sigma^{2}}S^{2}\sim\chi_{2}^{2}$$. To
finish the induction we have to prove that
$$\frac{\left(n-1\right)}{\sigma^{2}}S_{n}^{2}\sim\chi_{n-1}^{2}$$ if
$$\frac{\left(n-2\right)}{\sigma^{2}}S_{n-1}^{2}\sim\chi_{n-2}^{2}$$
(remember the subscript on the $$S^{2}$$ is the subscript necessary for
induction). Now the induction step requires

$$\frac{\left(n-1\right)}{\sigma^{2}}S_{n}^{2}=\frac{\left(n-2\right)}{\sigma^{2}}S_{n-1}^{2}+\left(\frac{n-1}{\sigma^{2}n}\right)\left(X_{n}-\bar{X}_{n-1}\right)^{2}$$

which is true because of a very length algebraic manipulation. Now
observe that the random vector $$\left(X_{n},\bar{X}_{n-1}\right)$$ is
independent of $$S_{n-1}^{2}$$ since as before $$\bar{X}_{n-1}$$ is
independent of $$S_{n-1}^{2}$$ and $$X_{n}$$ is definitely independent of
$$S_{n-1}^{2}$$ since $$X_{n}$$ is “in the future”. And finally since
$$X_{n}-\bar{X}_{n-1}\sim\mathcal{N}\left(0,n\sigma^{2}/\left(n-1\right)\right)$$
and by the induction hypothesis

$$\frac{\left(n-1\right)}{\sigma^{2}}S_{n}^{2}=\chi_{n-2}^{2}+\chi_{1}^{2}=\chi_{n-1}^{2}$$


■

Now what does *this* buy us? Well as mentioned, in general you have no
idea what $$\sigma^{2}$$ for a population is so computing

$$P\left(\bar{X}-1.96\sqrt{\frac{\sigma^{2}}{n}}<\mu<\bar{X}+1.96\sqrt{\frac{\sigma^{2}}{n}}\right)$$

i.e.

$$P\left(-1.96<\frac{\bar{X}-\mu}{\grave{\sqrt{\sigma^{2}/n}}}<1.96\right)$$

is impossible. But what about

$$P\left(a<\frac{\bar{X}-\mu}{\grave{\sqrt{S^{2}/n}}}<b\right)$$

Well

$$\begin{align}
T=\frac{\bar{X}-\mu}{\grave{\sqrt{S^{2}/n}}} & =\frac{\left(\bar{X}-\mu\right)\frac{\sqrt{n}}{\sigma}}{\sqrt{\frac{\left(n-1\right)S^{2}/\sigma^{2}}{\left(n-1\right)}}}=\frac{Z}{\sqrt{V/v}}\end{align}$$

where $$v=n-1$$, $$Z\sim\mathcal{N}\left(0,1\right)$$, and
$$V\sim\chi_{n-1}^{2}$$ and $$V$$ is independent of $$Z$$ since yet again
$$S^{2}$$ is independent of $$\bar{X}$$. This is the exact form of a
Student’s t distribution with $$v=n-1$$ degrees of freedom, i.e.
$$T\sim T\left(v\right)\sim T\left(n-1\right)$$. The density is

$$f_{T}\left(t\right)=\frac{\Gamma\left(\frac{v+1}{2}\right)}{\sqrt{v\pi}\Gamma\left(\frac{v}{2}\right)}\left(1+\frac{t^{2}}{v}\right)^{-\frac{v+1}{2}}$$

and so now we can compute “t test statistics”. Let $$a$$ be such that
$$P\left(-a<T<a\right)=.90$$ then

$$\begin{align}
P\left(-a<\frac{\bar{X}-\mu}{\grave{\sqrt{S^{2}/n}}}<a\right) & =P\left(\bar{X}-a\sqrt{\frac{S^{2}}{n}}<\mu<\bar{X}-a\sqrt{\frac{S^{2}}{n}}\right)=.90\end{align}$$

and so if we draw from our population the interval
$$\left(\bar{X}-a\sqrt{\frac{S^{2}}{n}},\bar{X}+a\sqrt{\frac{S^{2}}{n}}\right)$$
will “cover” the true mean with probability .9, i.e. it is a 90%
confidence interval for $$\mu$$. Quoting wikipedia:

> “Therefore, if we find the mean of a set of observations that we can
> reasonably expect to have a normal distribution, we can use the
> t-distribution to examine whether the confidence limits on that mean
> include some theoretically predicted value – such as the value
> predicted on a null hypothesis.”

# Central Limit theorem 

The central limit theorem is magical.

**Theorem 2.** If $$X_{i}$$ are all i.i.d with $$E\left(X_{i}\right)=\mu$$
and $$\text{Var}\left(X_{i}\right)=\sigma^{2}$$ and let

$$\bar{X_{n}}=\frac{1}{n}\sum_{i=1}^{n}\left(X_{i}-\mu\right)$$

the sampling distribution and

$$T_{n}=\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{\sigma}$$

Then
$$\underset{n\rightarrow\infty}{\lim}F_{T_{n}}\left(t\right)=F_{Z}\left(t\right)$$
where $$Z\sim\mathcal{N}\left(0,1\right)$$. That is to say $$T_{n}$$
converges in distribution to a standard normal.
Think about this. Regardless of the random variables (no matter what
they themselves are distributed as), as long as their mean and variance
exist, after centering, their properly normalized sum will converge to a
normal distribution.
The proof will use the characteristic function (fourier transform) and
so we need a couple of lemmas. The first one has to do with the
“smoothness” of characteristic functions

**Lemma 1.** For real $$t$$

$$\left|e^{it}-\sum_{k=0}^{n}\frac{\left(it\right)^{k}}{k!}\right|\leq\min\left\{ \frac{\left|t\right|^{n+1}}{\left(n+1\right)!},\frac{2\left|t\right|^{n}}{n!}\right\}$$

Afterward this result will be used to show that if $$E\left(X\right)=0$$
and $$\text{Var}\left(X\right)=\sigma^{2}<\infty$$ then its characteristic
function $$\phi_{X}\left(t\right)$$, to second order, is

$$\phi\left(t\right)=1-\frac{t^{2}\sigma^{2}}{2}+o\left(t^{2}\right)$$


**Proof Lemma 1.** Clearly this has something to do with the Taylor
series for $$e^{it}$$. So expand $$e^{it}$$

$$e^{it}=\sum_{k=0}^{n}\frac{\left(it\right)^{k}}{k!}+\frac{i^{n+1}}{\left(n\right)!}\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds$$

Then

$$\begin{align}
\left|e^{it}-\sum_{k=0}^{n}\frac{\left(it\right)^{k}}{k!}\right| &= \left|\frac{i^{n+1}}{\left(n\right)!}\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds\right|\end{align}$$

We estimate

$$\left|\frac{i^{n+1}}{\left(n\right)!}\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds\right|$$

in two different ways; one will be better when $$\left|t\right|$$ is small
and the other when $$\left|t\right|$$ is large. First the obvious thing is

$$\begin{align}
\left|e^{it}-\sum_{k=0}^{n}\frac{\left(it\right)^{k}}{k!}\right| &= \left|\frac{i^{n+1}}{\left(n\right)!}\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds\right|\\
 &= \frac{1}{\left(n\right)!}\left|\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds\right|\\
 &\leq \frac{1}{\left(n\right)!}\int_{0}^{t}\left|\left(t-s\right)^{n}e^{is}\right|ds\\
 &= \frac{1}{\left(n\right)!}\int_{0}^{t}\left|\left(t-s\right)^{n}\right|ds\\
 &\leq \frac{\left|t\right|^{n+1}}{\left(n+1\right)!}\end{align}$$

Alternatively since by integration by parts

$$\int_{0}^{t}\left(t-s\right)^{n-1}e^{is}ds=\frac{i}{n}\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds+\frac{t^{n}}{n}$$

i.e.

$$\begin{align}
\frac{i}{n}\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds &= \int_{0}^{t}\left(t-s\right)^{n-1}e^{is}ds-\frac{t^{n}}{n}\\
\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds &= \frac{n}{i}\left(\int_{0}^{t}\left(t-s\right)^{n-1}e^{is}ds-\frac{t^{n}}{n}\right)\end{align}$$

and so it’s the case that

$$\begin{align}
\left|e^{it}-\sum_{k=0}^{n}\frac{\left(it\right)^{k}}{k!}\right| &= \left|\frac{i^{n+1}}{\left(n\right)!}\int_{0}^{t}\left(t-s\right)^{n}e^{is}ds\right|\\
 &= \left|\frac{i^{n+1}}{\left(n\right)!}\frac{n}{i}\left(\int_{0}^{t}\left(t-s\right)^{n-1}e^{is}ds-\frac{t^{n}}{n}\right)\right|\\
 &= \frac{1}{\left(n-1\right)!}\left|\left(\int_{0}^{t}\left(t-s\right)^{n-1}e^{is}ds-\frac{t^{n}}{n}\right)\right|\\
 &\leq \frac{1}{\left(n-1\right)!}\left(\frac{\left|t\right|^{n}}{n}+\frac{\left|t\right|^{n}}{n}\right)=\frac{2\left|t\right|^{n}}{n!}\end{align}$$


■

Note that for large $$\left|t\right|$$ the tighter estimate is
$$\frac{2\left|t\right|^{n}}{n!}$$ (i.e. it’s smaller than
$$\frac{\left|t\right|^{n+1}}{\left(n+1\right)!}$$ ) and for small
$$\left|t\right|$$ the tighter estimate is
$$\frac{\left|t\right|^{n+1}}{\left(n+1\right)!}$$.
It’s a short hop skip and a jump away from the result of Lemma 1 to this

**Lemma 2.** If $$E\left(\left|X\right|^{n}\right)<\infty$$ then its
characteristic function is $$n$$ times continuously differentiable with
derivative

$$\phi^{\left(k\right)}\left(t\right)=i^{k}E\left(X^{k}e^{itX}\right)$$

and its Taylor series expansion is bounded

$$\left|\phi\left(t\right)-\sum_{k=0}^{n}E\left(X^{k}\right)\frac{\left(it\right)^{k}}{k!}\right|\leq E\left(\min\left\{ \frac{\left|tX\right|^{n+1}}{\left(n+1\right)!},\frac{2\left|tX\right|^{n}}{n!}\right\} \right)$$

and therefore $$o\left(\left|t\right|^{n}\right)$$ as $$t\rightarrow0$$.
Then in particular if $$E\left(X\right)=0$$ and
$$\text{Var}\left(X\right)=\sigma^{2}<\infty$$

$$\phi\left(t\right)=1-\frac{t^{2}\sigma^{2}}{2}+o\left(t^{2}\right)$$


**Proof Lemma 2.** Firstly

$$\frac{\phi\left(t+h\right)-\phi\left(t\right)}{h}=E\left(\frac{e^{i\left(t+h\right)X}-e^{itX}}{h}\right)=E\left(\frac{e^{ihX}-1}{h}e^{itX}\right)$$

and by Taylor’s theorem $$h\rightarrow0$$ (without worry about negativity
since $$h>0$$)

$$\lim_{h\rightarrow0}\frac{e^{ihX}-1}{h}e^{itX}=\lim_{h\rightarrow0}\frac{ihX}{h}e^{itX}=iXe^{itX}$$

and by lemma 2 for all $$h$$

$$\left|\frac{e^{ihX}-1}{h}e^{itX}\right|\leq\left|iXe^{itX}\right|\leq\left|X\right|$$

Since $$E\left(\left|X\right|^{n}\right)<\infty$$ all moments of
$$E\left(\left|X\right|^{j}\right)$$ for $$j<n$$ exist as well, i.e. all
$$\left|X\right|^{j}$$ are integrable, in particular $$\left|X\right|$$ and
so by the dominated convergence theorem

$$\phi'\left(t\right)=\lim_{h\rightarrow0}\frac{\phi\left(t+h\right)-\phi\left(t\right)}{h}=\lim_{h\rightarrow0}E\left(\frac{e^{i\left(t+h\right)X}-e^{itX}}{h}\right)=E\left(iXe^{itX}\right)$$

which by induction (and by similar arguments, i.e.
$$\left|X^{k}e^{itX}\right|\leq\left|X\right|^{k}$$) proves that

$$\phi^{\left(k\right)}\left(t\right)=i^{k}E\left(X^{k}e^{itX}\right)$$

Then by Jensen’s inequality

$$\begin{align}
\left|\phi\left(t\right)-\sum_{k=0}^{n}E\left(X^{k}\right)\frac{\left(it\right)^{k}}{k!}\right| &= \left|E\left(e^{itX}-\sum_{k=0}^{n}\frac{\left(itX\right)^{k}}{k!}\right)\right|\\
 &\leq E\left(\left|e^{itX}-\sum_{k=0}^{n}\frac{\left(itX\right)^{k}}{k!}\right|\right)\\
 &\leq E\left(\min\left\{ \frac{\left|tX\right|^{n+1}}{\left(n+1\right)!},\frac{2\left|tX\right|^{n}}{n!}\right\} \right)\end{align}$$

Then by dominated convergence again, as $$t\rightarrow0$$ (why???)

$$\left|t\right|^{n}E\left(\left|X\right|^{n}\min\left\{ \left|tX\right|,2\right\} \right)=o\left(\left|t\right|^{n}\right)$$

and so, as $$t\rightarrow0$$ (does that really meet the def of little o?)

$$\begin{align}
\phi\left(t\right) &\leq \sum_{k=0}^{n-1}E\left(X^{k}\right)\frac{\left(it\right)^{k}}{k!}+E\left(\min\left\{ \frac{\left|tX\right|^{n+1}}{\left(n+1\right)!},\frac{2\left|tX\right|^{n}}{n!}\right\} \right)\\
 &= 1+\frac{\left(it\right)}{1}E\left(X\right)+\frac{\left(it\right)^{2}}{2!}E\left(X^{2}\right)+E\left(\min\left\{ \frac{\left|tX\right|^{3+1}}{\left(4\right)!},\frac{2\left|tX\right|^{3}}{3!}\right\} \right)\\
 &= 1-\frac{t^{2}\sigma^{2}}{2!}+\frac{\left|t\right|^{3}}{3!}E\left(\left|X\right|^{3}\min\left\{ \frac{\left|tX\right|}{4},2\right\} \right)\\
 &= 1-\frac{t^{2}\sigma^{2}}{2!}+o\left(\left|t\right|^{2}\right)\end{align}$$


■

**Tiny Lemma 3:** For $$a_{i}$$ such that $$\lim_{i\to\infty}a_{i}=a$$

$$\lim_{n\to\infty}\left(1+\frac{a_{n}}{n}\right)^{n}=e^{a}$$


**Proof Tiny Lemma 3:** TODO

Finally we can prove Theorem 2, the central limit theorem

**Proof Theorem 2.** Define $$Y_{i}=\left(X_{i}-\mu\right)/\sigma$$ and
let $$\phi_{Y}\left(t\right)$$ be the characteristic function of the
$$Y_{i}$$. Then

$$S_{n}=\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{\sigma}=\frac{1}{\sqrt{n}}\sum_{i=1}^{n}Y_{i}$$

and then

$$\begin{align}
\phi_{\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{\sigma}}\left(t\right) &= \phi_{\frac{1}{\sqrt{n}}\sum_{i=1}^{n}Y_{i}}\left(t\right)\\
 &= \phi_{\sum_{i=1}^{n}Y_{i}}\left(\frac{t}{\sqrt{n}}\right)\\
 &= \left(\phi_{Y}\left(\frac{t}{\sqrt{n}}\right)\right)^{n}\end{align}$$

and by Lemma 2

$$\begin{align}
\left(\phi_{Y}\left(\frac{t}{\sqrt{n}}\right)\right)^{n} &= \left(1-\frac{t^{2}}{2n}+o\left(\left(\frac{t}{\sqrt{n}}\right)^{2}\right)\right)^{n}\\
 &= \left(1-\frac{1}{n}\left(\frac{t^{2}}{2}+n\cdot o\left(\frac{t^{2}}{n}\right)\right)\right)^{n}\end{align}$$

Now
$$o\left(\left(\frac{t}{\sqrt{n}}\right)^{2}\right)=o\left(\left(\frac{t^{2}}{n}\right)\right)$$
means there exists $$f\left(\frac{t^{2}}{n}\right)$$ such that

$$\frac{t^{2}}{2}+n\cdot o\left(\frac{t^{2}}{n}\right)=\frac{t^{2}}{2}+n\cdot f\left(\frac{t^{2}}{n}\right)$$

and

$$\lim_{n\to}\frac{f\left(\frac{t^{2}}{n}\right)}{t^{2}/n}=\lim_{n\to}n\cdot\frac{f\left(\frac{t^{2}}{n}\right)}{t^{2}}=0$$

therefore by tiny lemma 3

$$\begin{align}
\lim_{n\to\infty}\left(\phi_{Y}\left(\frac{t}{\sqrt{n}}\right)\right)^{n} &= \lim_{n\to\infty}\left(1-\frac{1}{n}\left(\frac{t^{2}}{2}+n\cdot o\left(\frac{t^{2}}{n}\right)\right)\right)^{n}\\
 &= e^{-t^{2}/2}\end{align}$$

which is the characteristic function of $$\mathcal{N}\left(0,1\right)$$.

■

Okay finally what’s the point? What does the central limit buy us? Well
for example suppose we were drawing iid from a population but all we
know about the population is that the distribution that describes it has
a finite mean $$\mu$$ and finite variance $$\sigma^{2}$$ but we’re again in
the same position we were that led us to Student’s $$t$$. So not only do
we not know the distribution of $$\bar{X}_{n}$$ but we don’t know
$$\sigma^{2}$$ either. We can then use the central limit theorem give an
approximate confidence interval (a confidence confidence interval?).
Since

$$\lim_{n\to\infty}\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{\sigma}\sim\mathcal{N}\left(0,1\right)$$

we might be able to claim that

$$\lim_{n\to\infty}\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{S_{n}}=\lim_{n\to\infty}\frac{\sigma}{S_{n}}\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{\sigma}\sim\mathcal{N}\left(0,1\right)$$

and then we would we have that for a large enough $$n$$

$$\begin{align}
\lim_{n\to\infty}P\left(-1.96<\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{S_{n}}<1.96\right) &= \lim_{n\to\infty}P\left(-1.96<Z<1.96\right)\\
 &\approx P\left(-1.96<Z<1.96\right)\\
 &\gtrapprox .95\end{align}$$

This depends on four results, one of which is the Strong Law of Large
numbers.

**Theorem 3 (Kolmogorow Strong Law of Large numbers):** Let $$X_{i}$$ be
iid random variables with $$E\left(X_{i}\right)=\mu$$. Then

$$\bar{X}_{n}\underset{a.s}{\to}\mu$$


**Proof:** Omitted
**Corollary:** For $$X_{i}$$ iid with finite mean and variancethe sample
variance is a consistent estimator of the the true variance, i.e.

$$\begin{align}
S_{n}^{2} & =\frac{1}{n-1}\sum_{i=1}^{n}\left(X_{i}-\bar{X}\right)^{2}\underset{a.s}{\to}\sigma^{2}\end{align}$$


**Proof of corollary:** By Kolmogorov SLLN and the sample manipulation
as in theorem 1

$$\begin{align}
\lim_{n\to\infty}S_{n}^{2} & =\lim_{n\to\infty}\frac{1}{n-1}\left(\sum_{i=1}^{n}\left(X_{i}\right)^{2}-n\left(\bar{X}_{n}\right)^{2}\right)\\
 & =\lim_{n\to\infty}\frac{n}{n-1}\left(\frac{\sum_{i=1}^{n}\left(X_{i}\right)^{2}}{n}-\left(\bar{X}_{n}\right)^{2}\right)\\
 & =1\cdot\left(E\left(X_{i}^{2}\right)-\mu^{2}\right)=\sigma^{2}\end{align}$$


**Lemma 5: $$\sigma/S_{n}\underset{a.s}{\to}1$$**

**Proof Lemma 5:** Since continuous function of a sequence of random
variables that converge to a limit itself converges to the function
evaluated at that limit we have by the corollary above that
$$\sqrt{S_{n}^{2}}\underset{a.s}{\rightarrow}\sqrt{\sigma^{2}}$$ and
therefore $$\sigma/S_{n}\underset{a.s}{\rightarrow}1$$.

**Lemma 6 (Slutsky’s Theorem):** If $$U_{n}\underset{D}{\to}U$$ and
$$Y_{n}\underset{P}{\to}a$$ then $$Y_{n}U_{n}\underset{D}{\to}aU$$.

**Proof:** Omitted
Finally letting $$Y_{n}=\sigma/S_{n}$$ and
$$U_{n}=\sqrt{n}\left(\bar{X}_{n}-\mu\right)/\sigma$$ we have

$$\lim_{n\to\infty}\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{S_{n}}=\lim_{n\to\infty}\frac{\sigma}{S_{n}}\frac{\sqrt{n}\left(\bar{X}_{n}-\mu\right)}{\sigma}\sim\mathcal{N}\left(0,1\right)$$
