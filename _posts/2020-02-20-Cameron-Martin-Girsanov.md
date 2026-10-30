---
layout: post
title: Cameron-Martin-Girsanov
published: true
tags: [probability]
---

This post makes rigorous the material in the previous two posts ([Change of Measure]({% post_url 2020-02-17-Change-of-Measure %})
and [Girsanov Theorem]({% post_url 2020-02-19-Girsanov-Theorem %}) 
).

# Radon-Nikodym

**Definition**: Two probability measure $P,Q$ are said to be **equivalent** if they pick the same measure-zero sets, i.e. $P(A) = 0 \iff Q(A) = 0$.

**Example**: Let $Z$ be a random variable (rv) against measure $P$ such that $E^P[Z] = 1$ and $Z>0$. Then 

$$
	Q(A) = E^P[Z\, 1_A] = \int\limits_A Z dP
$$

for all events $A$. Then $Q$ is equivalent to $P$. The assumption that $E^P[Z] = 1$ is required to guarantee $Q(\Omega) = 1$; if only $E^P[Z] < \infty$ then we could normalize $Z$ in the integral and still handily define the measure $Q$.

**Definition**: When $Q$ is defined as such then we write 

$$
	dQ := zdP \quad \text{or} \quad \frac{dQ}{dP} := z
$$

where $z$ is the density of $Z$.

**Theorem**: (Radon-Nikodym) Two measures $Q,P$ are equivalent iff there exists a random variable $Z$ such that $E^P[Z] = 1$ and $Q$ is defined as above. $z$ is called the **Radon-Nikodym** derivative of $Q$ w.r.t. $P$.

# Martingales

Martingales are stochastic processes that are "fair". First we need some standard definitions.

**Definition**: Let $(\Omega, \mathscr{F}, P)$ be a probability space and let $I$ be a totally ordered index set (usually $\mathbb{R}^+$ or $\mathbb{N}$). 
Also for every $i \in I$ let $\mathscr{F}_i$ be a sub-$\sigma$-algebra of $\mathscr{F}$.
Then the sequence $(\mathscr{F}_i)$ is called a **filtration**, if 

$$
	\mathscr{F}_k \subseteq \mathscr{F}_\ell \subseteq \mathscr{F}
$$

for all $k \leq \ell$. 
In short, filtrations are families of monotonic (in terms of inclusion) $\sigma$-algebras.
If $(\mathscr{F}_i)$ is a filtration then $\left( \Omega, \mathscr{F},(\mathscr{F}_i), P \right)$ is called a **filtered probability space**.

**Definition**: A stochastic process $Z: T \times \Omega \rightarrow S$ is a **Martingale** w.r.t. a filtration $\mathscr{F}_t$ and probability measure $P$ if

1. $Z_t$ is *adapted* to the filtration, i.e. for each $t$ in the index set $T$, $Z_t$ is $\mathscr{F}_t$-measurable.
2. $Z_t \in L^1$, i.e. 

	$$ 
		E^P[|Z_t| | \mathscr{F}_s] < \infty 
	$$

3. For all $s < t$  

$$ 
\begin{aligned}
E^P[Z_t - Z_s &| \mathscr{F}_s] = 0 \\
&\iff \\
E^P[Z_t &| \mathscr{F}_s] = Z_s \\
\end{aligned}
$$

is a Martingale for every $n$.

Suppose $T>0$ is fixed and $Z$ is a Martingale.
Define

$$
	dQ = z_T dP
$$

and $X$ a rv.
Then

$$
	E^Q [X] := E^P[Z_T X] = \int z_T X dP
$$

Similarly conditional expectation 
$E^Q [X | \mathscr{F}]$ 
(conditioned on some $\mathscr{F}$ and for some event $F \in \mathscr{F}$) is defined as the unique rv such that

$$
	\int_F E^Q [X | \mathscr{F}] dQ = \int_F x\, dQ
$$


**Definition**: Let $X_t$ be a stochastic process.
The **quadratic variation** $[X]_t$ is defined

$$
	[X]_t := \lim_{\lvert \Pi \rvert \rightarrow 0} \sum_{k=1}^n \left( X_{t_k} - X_{t_{k-1}}\right)^2
$$

where $\Pi$ ranges over partitions of $[0, t]$ and $\lvert \Pi \rvert \rightarrow 0$ means as the maximum length of a sub-interval goes to $0$.
The **covariation** of two processes $X,Y$ is 

$$
[X,Y]_{t}={\tfrac{1}{2}}([X+Y]_{t}-[X]_{t}-[Y]_{t})
$$

# Levy's theorem

**Theorem**: Suppose $X_t$ is a continuous Martingale such that that $P(X_0 = 0) = 1$ and $X_t$ has finite quadratic variation. Then $X_t$ is a Brownian motion.

# Cameron-Martin-Girsanov

**Theorem**: Let $B_t$ be a Brownian motion under some measure $P$ and let $\mu_t$ be adapted to the same filtration as $B_t$ (so that they're jointly $\mathscr{F}_t$-measurable).
Define 

$$
	\tilde{B}_t := B_t - \int_0^t \mu_s ds
$$

and 

$$
	Z_t := e^{\int_0^t \mu_t dB - \frac{1}{2}\int_0^t \mu_s^2 ds}
$$

and 

$$
	dQ = z_t dP
$$

If $Z_t$ is a Martingale under $P$ then $\tilde{B}_t$ is a Brownian motion under $Q$ (up to time $T$).

Note that $P(Z_0 = 0) = 1$ and if $Z_t$ is a Martingale then $E^P[Z_T] = 1$, thereby ensuring that $Q$ is a probability measure (the 1 "propagates").
The Martingale requirement is a hard constraint. 
In general $Z_t$ is a super-Martingale and so $E^P[Z_T] \leq 1$ (which foils $Q$ being a finite probability measure if $<1$). 
Two conditions that guarantee that $Z$ is a Martingale are the **Novikov** and **Kazamaki** conditions

$$
	E^P\left[e^{\frac{1}{2}\int_0^t \mu_s^2 ds}\right] < \infty \quad \text{or} \quad E^P\left[e^{\frac{1}{2}\int_0^t \mu_s dB}\right] < \infty
$$

but these often do not apply and proving that $Z_t$ is Martingale is required.

Note that, since $[\tilde{B}]_t = [B]_t = t$[^1], if we can show that $\tilde{B}_t$ is a Martingale under the new measure $Q$, then by Levy's criteria $\tilde{B}_t$ will be a Brownian motion. We now develop some techniques for showing that processes are Martingales under the new measure $Q$.

**Lemma**: Let $0 \leq s \leq t \leq T$ and $X$ be adapted to $\mathscr{F}_t$. Then

$$
	E^Q \left[ X | \mathscr{F}_s \right] = \tfrac{1}{Z_s} E^P \left[ Z_t X | \mathscr{F}_s\right]
$$

**Proof**: Let $A \in \mathscr{F}_s$. Then

$$
	\begin{aligned}
		\int_A E^Q \left[ X | \mathscr{F}_s \right]	dQ &= 		\int_A E^Q \left[ X | \mathscr{F}_s \right]	Z_T dP \\
	&= 	\int_A E^P\left[ E\left[ X | \mathscr{F}_s \right]	Z_T | \mathscr{F}_s\right]  dP \\
	&=  \int_A E^Q \left[ X | \mathscr{F}_s \right]	Z_s dP \\
	\end{aligned}
$$

Note $Z_T \rightarrow Z_s$. 
Also

$$
	\begin{aligned}
		\int_A E^Q \left[ X | \mathscr{F}_s \right]	dQ &= \int_A X dQ \\
		&= \int_A X Z_T dP \\
		&= \int_A E^P \left[ X Z_T | \mathscr{F}_s\right] dP \\
		&= \int_A Z_t X dP \\
		&= \int_A E^P \left[ Z_t X | \mathscr{F}_s \right] dP
	\end{aligned}
$$

Note $Z_T \rightarrow Z_t$. Thus

$$
	\int_A E^Q \left[ X | \mathscr{F}_s \right]	Z_s dP = \int_A E^P \left[ Z_t X | \mathscr{F}_s \right] dP
$$

Since the integrands are both $\mathscr{F}_s$-measurable they're both equal and so we have (after division) that 

$$
	E^Q \left[ X | \mathscr{F}_s \right] = \tfrac{1}{Z_s} E^P\left[ Z_t X | \mathscr{F}_s \right]
$$

**Lemma**: An adapted process $M$ is a Martingale under $Q$ iff $MZ$ is a Martignale under $P$.

**Proof**: Suppose $MZ$ is a Martingale under $P$. Then

$$
	E^Q \left[ M_t | \mathscr{F}_s \right] = \tfrac{1}{Z_s} E^P \left[ Z_t M_t | \mathscr{F}_s \right] = \tfrac{1}{Z_s} Z_s M_s = M_s
$$

by the preceding lemma (showing the forward direction). 
Conversely suppose that $M$ is a Martingale under $Q$. Then

$$
	E^P \left[ M_t Z_t | \mathscr{F}_s \right] = Z_s E^Q \left[ M_t | \mathscr{F}_s \right] = Z_s M_s
$$

hence proving the reverse direction.

**Proof of Cameron-Martin-Girsanov**: $\tilde{B}_t$ is clearly continuous and as already mentioned $[\tilde{B}]_t = t$.
Therefore it remains to show that $\tilde{B}_t$ is a Martingale under $Q$.
By the preceding lemma if we can show that $Z_t \tilde{B}_t$ is a Martingale under $P$ then we're done. 
To show that $Z_t \tilde{B}_t$ is a Martingale, we use Ito's product rule[^2] and Ito's formula[^3].

First consider, with $X_t = \int_0^t \mu_s dB_s$,

$$
	f(X_t, t) = e^{X_t - \tfrac{1}{2}\int_0^t \mu_s^2 ds }
$$

Then by Ito's formula

$$
\begin{aligned}
	dZ_t &= Z_t \left( -\tfrac{1}{2} Z_t \mu_t^2 dt + Z_t \mu_t dB_t + \tfrac{1}{2}Z_t \mu_t^2 dB_t\right)\\
	&= Z_t \mu_t dB_t
\end{aligned}
$$

and by Ito's product rule 

$$
\begin{aligned}
	d(Z_t \tilde{B}_t) &= Z_t d\tilde{B}_t + B_t dZ_t + dZ_t d\tilde{B}_t \\
	&= Z_t dB_t + Z \mu_t dt + \tilde{B}_t Z_t \mu_t dB_t - \mu_t Z dt\\
	&= Z_t(1- \tilde{B}_t \mu_t) dB_t
\end{aligned}
$$

Notice the use of $\tilde{B}_t$ *and* $B_t$. 

Alternatively (using the Ito integral form of $Z_t \tilde{B}_t)$

$$
	Z_t \tilde{B}_t = \int_0^t Z_t(1- \tilde{B}_t \mu_t) dB_t
$$

and therefore[^4] $Z_t \tilde{B}_t$ is a Martingale under $P$ and by the preceding lemma $\tilde{B}_t$ is a Martingale under $Q$.
Therefore $\tilde{B}_t$ is a Brownian motion under $Q$.

# Foonotes

[^1]: **Proof**: 
	For any partiation $\Pi = \{t_0, t_1, \dots, t_n \}$ where $t_n = T$  we have that 

	$$
		\begin{aligned}
		E \left[ \sum_{i=0}^{n-1} \left( B_{t_{i+1}} - B_{t_i}\right)^2\right] &= \sum_{i=0}^{n-1} (t_{j+1} - t_j) = T \\
		Var \left[ \sum_{i=0}^{n-1} \left( B_{t_{i+1}} - B_{t_i}\right)^2\right] &= \sum_{i=0}^{n-1} 3(t_{j+1} - t_j)^2 = T \\
		& \leq 3 T \lvert \Pi \rvert 
		\end{aligned}
	$$

	since Brownian motion increments are independent and Normally distributed with variance equal to $t_j - t_i$ for $t_j > t_i$.
	And thus (since $Var \rightarrow 0$ as $\lvert \Pi \rvert \rightarrow 0$) 

	$$
		\lim_{\lvert \Pi \rvert \rightarrow 0} \left[ \sum_{i=0}^{n-1} \left( B_{t_{i+1}} - B_{t_i}\right)^2\right] = T
	$$

[^2]: If $X_t$ is an Ito process satisfying the stochastic differential equation

	$$
		dX_t = \mu_t dt + \sigma_t dB_t
	$$

	where $B_t$ is a Brownian motion we have for $f := f(X_t ,t)$

	$$
		df = \left( \frac{\partial f}{\partial t} + \mu_t \frac{\partial f}{\partial x} + \tfrac{1}{2}\sigma_t \frac{\partial^2 f}{\partial x^2}\right)dt + \sigma_t \frac{\partial f}{\partial x} dB_t
	$$

[^3]: Let $X_t, Y_t$ be two Ito processes. Then

	$$
		d(X_t Y_t) = X_t dY_t + Y_t dX_t + dX_t dY_t
	$$

[^4]: **Theorem**: If $E^P \left[ \int_0^t X_s ds \Big\lvert \mathscr{F}_s \right] < \infty$ then $\int_0^t X_s dB_s$ is a Martingale.