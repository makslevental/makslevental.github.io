---
layout: post
title: Black-Scholes intuition
published: true
tags: [probability, finance]
---

This post follows [the series of videos starting with this one](https://youtu.be/-qa2B_sCpZQ?list=PLS3zAvd8Oxey3aBAZuglIpQYWhQSH0VTc) and covers derivations of the Black-Scholes model for pricing a European option.

The Black-Scholes partial differential equation (PDE) is 

$$
    \frac{\partial V}{\partial t} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} + r S \frac{\partial V}{\partial S} - rV = 0
$$

we will define terms and derive it through various means in the forthcoming.

# Brownian motion

The **arithmetic Brownian motion** is defined as the solution $X_t$ to the stochastic differential equation

$$
    dX_t = \mu dt + \sigma dB_t
$$

where $\mu$ is called the **drift term** (because on average the process moves/drifts in that direction) and $\sigma$ the **diffusion term** (because this stochastic term causes the process to diffuse).

In contrast consider the **geometric Brownian motion**

$$
    dX_t = X_t \left( \mu dt + \sigma dB_t\right) 
$$

Notice that 

$$
    \frac{dX_t}{X_t} = \mu dt + \sigma dB_t
$$

therefore we use the *ansatz*[^1] $Y_t = \log X_t$.
Applying Ito's lemma to both sides 

$$
\begin{aligned}
    \frac{dX_t}{X_t} &= \frac{dX_t}{X_t} - \frac{1}{2} \frac{dX_t^2}{X_t^2}\\
    &= \left( \mu - \tfrac{1}{2} \sigma^2\right)dt + \sigma dB_t
\end{aligned}
$$

where we use that after applying to $dX_t^2$ and only considering first order and second order terms we have $dX_t^2 = \sigma^2 X_t^2 dt$.

Integrating

$$
    \begin{aligned}
    \log X_t &= \int\limits_0^T \left( \mu - \tfrac{1}{2} \sigma^2\right)dt +  \int\limits_0^T\sigma dB_t \\
    &= \left( \mu - \tfrac{1}{2} \sigma^2\right)T +  \sigma B_T + \log X_0
    \end{aligned}
$$

Rearranging and exponentiating we get 

$$
    X_T = X_0 e^{\left( \mu - \tfrac{1}{2} \sigma^2\right)T +  \sigma B_T}
$$

and we thereby see whence the name **geometric** Brownian motion (because a logarithmic relation is typically described as geometric).

# Black-Scholes

In Black-Scholes we have a volatile asset (e.g. a stock) that obeys a geometric Brownian motion

$$
d S_t = S_t \left( \mu dt + \sigma dW_t \right)
$$

where $dW_t$ is a Brownian motion (renamed in order to distinguish from $B_t$ the value of the bank account), $S_t$ is the price of a stock, $\mu$ is the expected price for an infinitesmal period of time, and $\sigma^2$ is the variance of the price over the same period of time. 
We also have a bank account $B_t$ appreciating at a constant interest rate

$$
    dB_t = r B_t dt
$$

where $r$ is called the **risk-free rate**.

We seek to price a option (either call or put) on the stock. The option is a function of five variables

$$
    V \equiv V (T-t, S_t, \mu, r, \sigma, K)
$$

where $T-t$ is the time to maturity, $S_t$ is the current price of the stock, $\sigma$ the standard deviation of the stock, and $K$ is the strike price of the option. 

So our system of equations is 

$$
\begin{aligned}
    V &\equiv V (T-t, S_t, r, \mu, \sigma, K)\\ 
    dB_t &= r B_t dt \\
    d S_t &= S_t \left( \mu dt + \sigma dW_t \right)
\end{aligned}
$$

We know from Ito's lemma that (since $V$ is a function of a stochastic process $S_t$)

$$
    dV = \frac{\partial V}{\partial t} dt + \frac{\partial V}{\partial S_t} dS_t + \frac{1}{2} \frac{\partial^2 V}{\partial S_t^2} dS_t^2
$$

Hence (dropping the subscript $t$ for notational convenience)

$$
\begin{aligned}
    dV &= \frac{\partial V}{\partial t} dt + \frac{\partial V}{\partial S} dS + \frac{1}{2} \frac{\partial^2 V}{\partial S^2} dS^2 \\
    &  \frac{\partial V}{\partial t} dt + \frac{\partial V}{\partial S} \left(S \left( \mu dt + \sigma dW \right)\right) + \frac{1}{2} \frac{\partial^2 V}{\partial S^2} dS^2 \\
    &= \frac{\partial V}{\partial t} dt + \frac{\partial V}{\partial S} \left(S \left( \mu dt + \sigma dW \right)\right) + \frac{1}{2} \frac{\partial^2 V}{\partial S^2} \sigma^2 S^2 dt \\
    &= \left( \frac{\partial V}{\partial t} + \mu S\frac{\partial V}{\partial S} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} \right) dt + \sigma S \frac{\partial V}{\partial S} dW
\end{aligned}
$$

where we've used the geometric Brownian motion relation $dS_t^2 = \sigma^2 S_t^2 dt$
and there are no derivatives dependent on $r, \sigma, \mu, K$ since they're constants.

We recognize this as an Ito process with a drift term and a stochastic term.

# Delta hedging 

Delta hedging means hedging (guarding) against the risk in the option by simultaneously trading in the underlying asset (e.g. stock).
Since both the option and the asset are driven (adapted to) by the same Brownian motion we can eliminate most[^4] of the risk in this way.

The questions to resolve are how many units of the underyling asset to buy or sell, when to buy or sell, and until when to stay in the hedge.
Assume we are short in a call option[^2]; to hedge this position we take a long position in the underlying[^3]. 
To this end we assume that we have access to bank account with exactly the necessary funds; debt that we'll repay accrues interest at the risk free rate (and conversely the bank pays us a coupon at the risk free rate for any excess cash).

Suppose we buy $\Delta S$ units of the stock and borrowing $\alpha B$ units of the bank account in order to make this purchase. 
Then our portfolio (including the option premium $V$) value is

$$
\begin{aligned}
    \Pi &= \Delta S + \alpha B + V\\
    d\Pi &= \Delta dS + \alpha dB + dV
\end{aligned}
$$

where both $\Delta$ and $\alpha$ can be negative.

Making substitutions for $dS$ and $dB$ and $dV$

$$
\begin{aligned}
    d\Pi &= \Delta \left( \mu S_t dt + \sigma S_t dW_t \right) + \alpha r B dt + \left( \frac{\partial V}{\partial t} + \mu S\frac{\partial V}{\partial S} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} \right) dt + \sigma S \frac{\partial V}{\partial S} dW\\
    &= \left( \Delta \mu S + \alpha r B + \frac{\partial V}{\partial t} + \mu S\frac{\partial V}{\partial S} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} \right)dt + \left(\Delta \sigma s + \sigma S \frac{\partial V}{\partial S}\right) dW
\end{aligned}
$$

Our aim is to choose $\Delta$ such that the coefficient of the stochastic term becomes zero 

$$
    \Delta \sigma s + \sigma S \frac{\partial V}{\partial S} \equiv 0
$$

which implies

$$
    \Delta = -\frac{\partial V}{\partial S}
$$

Making this substitution into $\Pi$ we get

$$
    \Pi = V -\frac{\partial V}{\partial S} S + \alpha B
$$

and into $d\Pi$ we get

$$
\begin{aligned}
    d\Pi &= \left(\frac{\partial V}{\partial t} + \mu S \frac{\partial V}{\partial S} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} - \frac{\partial V}{\partial S} \mu S + ar B \right)dt \\
    &= \left( \frac{\partial V}{\partial t} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} + arB \right) dt
\end{aligned}
$$

Now we invoke the abitrage-free assumption: since $d\Pi$ has no $dW$ terms it must grow at the risk-free rate (because without any volatility it is effectively risk-less).
Therefore

$$
\begin{aligned}
    d\Pi &= \Pi r dt \\
    &= \left( V -\frac{\partial V}{\partial S} S + \alpha B  \right)r dt
\end{aligned}
$$

Comparing coefficients of $dt$ from both sides of $d\Pi$ we get 

$$
    \left( \frac{\partial V}{\partial t} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} + arB \right) = r V - r\frac{\partial V}{\partial S} S + \alpha rB 
$$

and cancelling we get the Black-Scholes PDE

$$
    \frac{\partial V}{\partial t} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} + r S \frac{\partial V}{\partial S} - rV = 0
$$

or 

$$
    \frac{\partial V}{\partial t} + \tfrac{1}{2} \sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} = r \left(V - S \frac{\partial V}{\partial S}\right)
$$

This form makes the intuition of the PDE clear: the right hand side is the return generated by the bank account (whose balance consists of the appreciating option premium, since we sold a call option, minus the accruing debt initially incurred when borrowing in order to purchase $\Delta$ units of the stock) while the left hand side is the change in derivative value.
The first term, with respect to time, is called **theta**, captures the effect of the approaching maturity date, and the second term, called **gamma**, captures the remaining (second order) risk despite the Delta hedge.

# Change of Measure

Under risk-neutral measure $P$ the dynamics of $S_t$ are

$$
    dS_t = r S_t dt + \sigma S_t dB_t
$$

with solution

$$
    S_T = S_0 e^{\left( r -\tfrac{1}{2}\sigma^2 \right)T + \sigma B_T}
$$

The **price of a call option** under the risk neutral measure is just the discounted future expected pay-off

$$
    C_0 := e^{-rT} E^P \left[ (S_T -K) 1_{S_T > K}\right] = e^{-rT} E^P \left[ \max(S_T -K, 0) \right]
$$

where $1_{S_T > K}$ and $\max(S_T -K,0)$ enforce the fact that if the option expires out of the money then the value is 0.
Splitting the pay-off into two terms

$$
    \begin{aligned}
        C_0 &= e^{-rT} E^P \left[ (S_T -K) 1_{S_T > K}\right] \\
        &= e^{-rT} E^P \left[ S_T 1_{S_T > K} -K 1_{S_T > K}\right] \\
        &=  e^{-rT} E^P \left[ S_T 1_{S_T > K}\right] - Ke^{-rT} E^P \left[ 1_{S_T > K}\right]
    \end{aligned}
$$


The second term is simply the probability that at expiration $S_T > K$ under the risk-neutral measure $P$ i.e.

$$
\begin{aligned}
      Ke^{-rT} E^P \left[ 1_{S_T > K}\right] &= Ke^{-rT} P \left( S_T > K\right) \\
      &= Ke^{-rT} P \left( S_0 e^{\left( r -\tfrac{1}{2}\sigma^2 \right)T + \sigma B_T}> K\right) \\
      &= Ke^{-rT} P \left( \log(S_0) +  \left( r -\tfrac{1}{2}\sigma^2 \right)T + \sigma B_T> \log(K)\right) \\
      &= Ke^{-rT} P \left( B_T> \frac{\log(K)-\log(S_0) -  \left( r -\tfrac{1}{2}\sigma^2 \right)T}{\sigma }\right) \\
\end{aligned}
$$

Now we know that $B_T \sim N(0,T)$ and therefore

$$
    \frac{B_T}{\sqrt{T}} \sim N(0,1)
$$

hence we can compute the probability $P(\cdots)$ evaluating the cumulative distribution function of a $(0,1)$-Normal, i.e. 

$$
    Ke^{-rT} E^P \left[ 1_{S_T > K}\right] = Ke^{-rT} \Phi(d_2)
$$

where 

$$
    d_2 := \frac{-\log(K)+\log(S_0) +  \left( r -\tfrac{1}{2}\sigma^2 \right)T}{\sigma \sqrt{T}}
$$

where we've multiplied everything by $-1$ in order to use the symmetry of the Normal distribution i.e. the probability of $X > k$ is equal to the probability that $X < -k$.

The first term 

$$
    \begin{aligned}
        e^{-rT} E^P \left[ S_T 1_{S_T > K}\right] &= e^{-rT} E^P \left[ S_0 e^{\left( r -\tfrac{1}{2}\sigma^2 \right)T + \sigma B_T} 1_{S_T > K}\right] \\
        &= e^{-rT} E^P \left[ S_0 e^{rT}e^{-\tfrac{1}{2}\sigma^2 T + \sigma B_T} 1_{S_T > K}\right] \\
        &= S_0 E^P \left[e^{-\tfrac{1}{2}\sigma^2 T + \sigma B_T} 1_{S_T > K}\right] \\
    \end{aligned}
$$

where we've taken out of the expectation $e^{rT}$ and $S_0$ because they are constants w.r.t. $P$.
Recall Cameron-Martin-Girsanov: if $B_t$ is a Brownian motion under $P$ and we shift by $Y_t := \sigma t$ then $\tilde{B} := B_t - \sigma t$ will be a Brownian motion under a new measure $Q$ defined by its Radon-Nikodym derivative w.r.t. the old measure

$$
    \frac{dQ}{dP} := e^{\sigma B_t - \tfrac{1}{2}\sigma^2 t}
$$

Thus we have for 

$$
    \begin{aligned}
        e^{-rT} E^P \left[ S_T 1_{S_T > K}\right] &= S_0 E^P \left[e^{-\tfrac{1}{2}\sigma^2 T + \sigma B_T} 1_{S_T > K}\right] \\
        &= S_0 E^P \left[\frac{dQ}{dP} 1_{S_T > K}\right] \\
        &= S_0 E^P \left[\frac{dQ}{dP} 1_{S_T > K}\right] \\
        &= S_0 E^Q \left[ 1_{S_T > K} \right]
    \end{aligned}
$$

and so we can use the same procedure as for the second term, except with $S_T$ obeying transformed dynamics

$$
\begin{aligned}
    S_T &= S_0 e^{\left( r -\tfrac{1}{2}\sigma^2 \right)T + \sigma B_T} \\
    &= S_0 e^{\left( r -\tfrac{1}{2}\sigma^2 \right)T + \sigma \left( \tilde{B}_T - \sigma T \right)} \\
    &= S_0 e^{\left( r +\tfrac{1}{2}\sigma^2 \right)T + \sigma \tilde{B}_T}
\end{aligned}
$$

which gives us

$$
    S_0 E^Q \left[ 1_{S_T > K} \right] = S_0 \Phi(d_1)
$$

where 

$$
    d_1 := \frac{-\log(K)+\log(S_0) +  \left( r + \tfrac{1}{2}\sigma^2 \right)T}{\sigma \sqrt{T}}
$$



# Footnotes

[^1]: "In physics and mathematics, an ansatz is an educated guess or an additional assumption made to help solve a problem, and which is later verified to be part of the solution by its results."

[^2]: We've sold call options.

[^3]: We buy the underlying (stock).

[^4]: As you'll see you can only eliminate first order risk this way (second order risk will remain).