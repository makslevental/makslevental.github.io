---
layout: post
title: Reed-Solomon Error Correcting Codes
published: true
use_math: true
excerpt_separator: <!--more-->
tags: [information-theory]
---

# Shannon's noisy-channel coding theorem

**Shannon's noisy-channel coding theorem** sets bounds on how much data can be sent across a noisy channel **nearly error free**.
The **Shannon capacity** of a channel is the maximum error-free data rate. <!--more-->

<p align="center">
  <img src="/images/shannon_channel_model.svg" width="550px"/>
</p>

* $$W$$ is the message to be transmitted
* $$X$$ is the channel input symbol ($$X^{n}$$ is a sequence of $$n$$ symbols called a **block**) with $$X \in \mathcal {X}$$ an alphabet
* Similarly $$Y, Y^n, \mathcal{Y}$$
* $$\hat{W}$$ is the estimate of the transmitted message
* $$f_n$$ is the encoding function for a block of symbols of length $$n$$
* Similarly $$g_n$$
* $$p(y\mid x)=p_{Y\mid X}(y\mid x)$$ is the noisy channel, modeled by a conditional probability distribution (the idea being that $$Y$$ is correlated with $$X$$ but not equal to $$X$$ due to noise)

Note that the marginal $$p_{X}(x)$$ completely determines the joint distribution $$p_{X,Y}(x,y)$$ by

$$
    p_{X,Y}(x,y)=p_{Y|X}(y|x)\,p_{X}(x)
$$

and induces **mutual information** $$\operatorname {I} (X;Y)$$ (as a function of $$p_{Y}(y)$$)

$$
\operatorname {I} (X;Y):= \sum _{y\in {\mathcal {Y}}}\sum _{x\in {\mathcal {X}}}{p_{X,Y}(x,y)\log {\left({\frac {p_{X,Y}(x,y)}{p_{X}(x)\,p_{Y}(y)}}\right)}}
$$

Define the **probability of block error**

$$
P_e := P\left( \hat{W} \neq W \right)
$$




**Theorem**: Shannon's noisy-channel coding theorem

1. For a discrete, memoryless[^1] channel, the channel capacity 
    $$
        C=\sup _{p_{X}}I(X;Y)
    $$
    has the properties that for any $$\varepsilon > 0 $$ and any $$R < C$$, there exists a long enough block code of length $$N$$ and rate $$R < R' < C$$ such that transmitting messages at rate $$R'$$ incurs $$P_e \leq \varepsilon$$.
2. For a binary code, if the probability of bit error $$p_b$$ is acceptable, then rates up to 
    $$
        R(p_b) := \frac{C}{1 - H_2 (p_b)}
    $$
    are achievable, where $$H_{2}(p_{b})=-\left[p_{b}\log _{2}{p_{b}}+(1-p_{b})\log _{2}({1-p_{b}})\right]$$ is the **binary entropy**.
3. For any probability of bit error $$p_b$$, rates greater than $$R(p_b)$$ are not achievable.

# Reed & Solomon's original view

## Encoding

Let $$x:=(x_{1},\dots ,x_{k})$$ be the message with $$x_i \in \mathbb{F}_q$$ a finite field of order $$q$$ (therefore $$q=p^m$$ for some prime $$p$$).
The codeword for $$x$$ is produced by mapping through a $$k-1$$ degree polynomial $$p_x \in \mathbb{F}_q[z]$$

$$
    p_{x}(z):=\sum _{i=1}^{k}x_{i}z^{i-1}
$$

by evaluating $$p_x$$ at $$n$$ different points $$a_{1},\dots ,a_{n}$$ of the field $$\mathbb{F}_q$$.
Thus the encoding function $$C = x \cdot A$$ where  

$$
    A=\begin{bmatrix}
        1&\dots &1&\dots &1\\
        a_{1}&\dots &a_{k}&\dots &a_{n}\\
        a_{1}^{2}&\dots &a_{k}^{2}&\dots &a_{n}^{2}\\
        \vdots &&\vdots &&\vdots \\
        a_{1}^{k-1}&\dots &a_{k}^{k-1}&\dots &a_{n}^{k-1}
    \end{bmatrix}
$$

## Decoding (Berlekamp–Welch algorithm)

Suppose $$b = (b_{1},\cdots ,b_{n})$$ are the received codewords corresponding to message $$x$$.
Berlekamp–Welch computes $${\displaystyle E(z)}$$, called the **error polynomial**, which identifies the error by $${\displaystyle E(a_{i})=0}$$ corresponding to errors in the received codeword.
Let $$e$$ be the number of errors in set of codewords (i.e. number of codewords that are corrupted).
The **key set** of $$n$$ equations is

$$
    b_{i}E(a_{i})-p_x(a_{i})=0
$$

where $$E(a_{i})=0$$ for $$e$$ errors and $$E(a_{i})\neq 0$$ for $$n-e$$ codewords (thus $$b_i = p_x(a_{i})$$ since $$\mathbb{F}_q[z]$$ is over a prime field $$\mathbb{F}_q$$).
If we define

$$
    Q(a_{i}):=E(a_{i})p_x(a_{i})
$$

for $$i = 0, \dots, e$$ cases and constrain $$E(a_{i})$$ to be monic[^2] ($$e_e = 1$$) we get a set of $$n$$ equations in $$n$$ unknowns

$$
b_{i}(e_{0}+e_{1}a_{i}+e_{2}a_{i}^{2}+\cdots +e_{e-1}a_{i}^{e-1})-(q_{0}+q_{1}a_{i}+q_{2}a_{i}^{2}+\cdots +q_{j}a_{i}^{q})=-b_{i}a_{i}^{e}
$$

where $$j = n - e - 1$$.
This can be solved using Gaussian elimination in $$O(n^3)$$ time.
Thus we can solve for $$Q(z)$$ and $$E(z)$$.
The algorithm assumes $$e = \lfloor \frac{n-k}{2} \rfloor$$ and $$e$$ is decremented if the system can't be solved.
Once the system is solved, if $$Q/E$$ has remainder 0 then $$p_x = Q/E$$ and the codeword values are recovered at $$a_i$$ where $$E(a_i) = 0$$.
Alternatively, if $$Q/E$$ does not have remainder 0, then an **uncorrectable code** has been detected.

# Footnotes

[^1]: The noise distribution at time $$t$$ doesn't depend on $$t' < t$$.
[^2]: The leading coefficient is 1.