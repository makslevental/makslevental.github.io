---
layout: post
title: Exact Solution Methods for Decision Problems
published: true
use_math: true
excerpt_separator: <!--more-->
tags: [ml]
---

# Definitions

## Markov Decision Process

A Markov Decision Process (MDP) models choosing an **action** $$a_t$$ in an **action space** $$\mathcal{A}$$ while in a **state** $$s_t$$ (from a **state space** $$\mathcal{S}$$) and thence receiving a reward $$r_t$$. <!--more-->
Choosing such an action *evolves* the process to a state $$s_{t+1}$$ according to a probability distribution $$P\left( S_{t+1} \mid S_t, A_t \right)$$ over states and actions[^1].
The **Markov assumption** assumes that $$S_{t+1}$$ only depends on $$S_t$$ and $$A_t$$ (rather than the entire history/trajectory of the process).
**Stationary** MDPs are those for which $$P\left( S_{t+1} \mid S_t, A_t \right)$$ does not vary in time (i.e. only depends on states and actions and not at which $$t$$ those states and actions were occupied/chosen).
Therefore, the **state transition model** $$T \left( s' \mid s, a \right)$$ represents that probability of transitioning from state $$s$$ to state $$s'$$ after choosing action $$a$$ and the **reward function** $$R(s,a)$$ represents the expected reward when executing action $$a$$ from state $$s$$.

## Rewards

$$R(s,a)$$ is a deterministic function of $$s,a$$ because it is an expectation but it may be "generated" stochastically; for example, if the reward depends on the next state (as given by a modified $$R(s,a,s')$$) then

$$
    R(s,a) = \sum_{s'} T(s' \mid s, a) R(s,a,s')
$$

In a **finite horizon** problem with $$n$$ decisions the **utility** associated (also called the **reward**) with a sequence of rewards $$r_{1:n} := r_1, r_2, \dots, r_n$$ is 

$$\sum_{t=1}^n r_t$$

In an **infinite horizon** the **discounted return** is given by

$$
    \sum_{t=1}^\infty \gamma^{t-1} r_t
$$

where $$0 \leq \gamma < 1$$ guarantees that the sum converges.
Note that the "first" return $$r_1$$ is "undiscounted" ($$\gamma^{1-1} = 1$$).

## Policies

Given a history of states and actions $$h_t := (s_{1:t}, a_{1:t})$$ a **policy** $$\pi_t(h_t)$$ sets which actions are taken at each time step.
Since for MDPs future states and rewards depend only on the current state, we restrict our attention to policies that only depend on the current state, i.e. $$\pi_t(h_t) \equiv \pi_t(s_t)$$.
A **deterministic policy** is one where the action taken is deterministically a function of the history.
Alternatively, a **stochastic policy** is one where the action taken is actually drawn from a probability distribution $$\pi_t(a_t \mid s_t)$$.
For infinite horizon problems with stationary transitions and rewards **stationary policies**, naturally, do not depend on time i.e.

$$
    \pi_t(s_t) \equiv \pi(s)
$$

Note that for finite horizon problems (even with stationary transitions and rewards) it maybe advantageous to consider non-stationary policies.

### Value functions

The **expected utility** of executing policy $$\pi$$ from state $$s$$ is denoted $$\mathcal{U}^{\pi}(s)$$.
For MDPs $$\,\mathcal{U}^{\pi}$$ is called the **value function** (because it captures the value of being in a state, given some policy for actions to take).
An **optimal policy** $$\pi^*$$ is a policy that maximizes expected utility

$$

    \pi^*(s) := \argmax_{\pi}\, \mathcal{U}^{\pi}(s) \text{ for all states } s
$$

The value function $$\mathcal{U}^{*}(s) := \mathcal{U}^{\pi^*}(s)$$ corresponding to the optimal policy is called the **optimal value function**.
An optimal policy can be found using dynamic programming[^3].




# Policy evaluation

**Policy evaluation** involves estimating the value function $$\mathcal{U}^\pi$$ forward in time.
This can be done inductively (iteratively); for a single step from the state $$s$$ the value function is just the reward received when performing action $$\pi(s)$$

$$
    \mathcal{U}^\pi_1 (s) := R(s, \pi(s))
$$

Then $$\mathcal{U}^\pi_{k+1} (s)$$ at some time step $$k+1$$ is estimated using the **lookahead** equation; the lookahead equation estimates $$\mathcal{U}^\pi_{k+1} (s)$$ by combining

1. the reward received by taking action $$\pi(s)$$ 
2. the average value of the $$k$$th (current) estimate of the policy, $$\mathcal{U}^\pi_{k} (s')$$, over all possible states $$s'$$ that can be transitioned to when starting in state $$s$$ and taking action $$\pi(s)$$

That is to say

$$
    \mathcal{U}^\pi_{k+1} (s) :=  R(s, \pi(s))  + \gamma \sum_{s'} T(s' \mid s, \pi(s))\, \mathcal{U}^\pi_k (s') 
$$

Note that since $$0 \leq \gamma < 1$$ it's the case that $$\mathcal{U}^\pi_{k} \rightarrow \mathcal{U}^\pi_{k+1}$$ is a contraction mapping[^2] and therefore policy evaluation converges 

$$
\mathcal{U}^\pi (s) := \lim_{k \rightarrow \infty} \mathcal{U}^\pi_{k+1} (s)
$$

and therefore for an infinite horizon problem, at convergence, we have

$$
    \mathcal{U}^\pi(s) =  R(s, \pi(s))  + \gamma \sum_{s'} T(s' \mid s, \pi(s))\, \mathcal{U}^\pi (s') 
$$

$$\mathcal{U}^\pi(s)$$ can also be solved for by solving a system of equations

$$
    \mathbf{U}^\pi = \mathbf{R}^\pi + \gamma \mathbf{T}^\pi \mathbf{U}^\pi
$$

where $$\mathbf{U}^\pi, \mathbf{R}^\pi$$ are $$\lvert \mathcal{S} \rvert$$-length vectors and $$\mathbf{T}^\pi$$ is a $$\lvert \mathcal{S} \rvert \times \lvert \mathcal{S} \rvert$$ matrix with state $$i$$ $$\rightarrow$$ state $$ j $$ transition probabilities $$T_{ij}^\pi$$.
Solving for $$\mathbf{U}^\pi$$ we get

$$
    \mathbf{U}^\pi = \left(\mathbf{I} - \gamma \mathbf{T}^\pi \right)^{-1}  \mathbf{R}^\pi
$$

which has runtime $$O(\lvert \mathcal{S} \rvert^3)$$.

## $$Q$$-function

An alternative way to represent an arbitrary value function $$\mathcal{U}(s')$$ is in terms of the action as well as the state, namely by the **action value function** (also called the **$$Q$$-function**)

$$
    Q(s,a) := R(s, a) + \gamma \sum_{s'} T(s' \mid s, a)\, \mathcal{U}(s') 
$$

Storing $$Q$$ costs $$O(\lvert \mathcal{S} \rvert \times \lvert \mathcal{A} \rvert)$$ as opposed to just $$O(\lvert \mathcal{S} \rvert)$$ for storing $$\mathcal{U}$$ but it saves having to store and query $$R, T$$.

# Value Function Policies

The previous section computed a value function given a policy. 
Similarly, given a value function $$\mathcal{U}(s)$$, we can compute the policy that maximizes that value function

$$
    \pi(s) := \argmax_{a} \left(  R(s, \pi(s))  + \gamma \sum_{s'} T(s' \mid s, \pi(s))\, \mathcal{U} (s')   \right)
$$

called the **greedy policy**.
If $$\mathcal{U}(s)$$ is the optimal value function then $$\pi(s)$$ is the optimal policy.

Both $$\mathcal{U}(s)$$ and $$\pi(s)$$ can be obtained from the $$Q$$-function

$$
    \begin{aligned}
        \mathcal{U}(s) &= \max_a Q(s,a)  \\
        \pi(s) &= \argmax_a Q(s,a)  \\
    \end{aligned}
$$

## Advantage function

Policies can also be represented using the **advantage function**, which quantifies the "advantage" of taking some action relative to the greedy action (action dictated by the greedy policy $$\mathcal{U}(s)$$)

$$
    A(s,a) = Q(s,a) - \mathcal{U}(s)
$$

Note that greedy actions have "zero advantage" and non-greedy actions have "negative advantage".

# Policy Iteration

**Policy iteration** is an algorithm for computing an optimal policy.
It starts with any policy (e.g. $$\pi(s) = 0$$) and alternates between policy evaluation and policy improvement (using the lookahead function).

```
def lookahead$\left(\mathcal{S}, T, R, \gamma, \mathcal{U}, s, a\right)$:
    return $R(s, a)  + \gamma \sum_{s' \in \mathcal{S}} T(s' \mid s, a)\, \mathcal{U}(s')$

def greedy_action$\left(\mathcal{S}, T, R, \mathcal{A}, \gamma, \mathcal{U}, s\right)$:
    return $\argmax_{a' \in \mathcal{A}}$ lookahead$\left(\mathcal{S}, T, R, \gamma, \mathcal{U}, s, a'\right)$

def policy_iteration$\big(\mathcal{S}, \pi, \mathcal{A}, T, R, \gamma,$k_max=100$\big)$:
    # vectorize by evaluating args
    for k = 1:k_max
        # perform policy evaluation
        $\mathbf{T}$ = $\big[T(s' \mid s, \pi(s))$ for $s \in \mathcal{S}$ for $s' \in \mathcal{S}\big]$
        $\mathbf{R}$ = $\big[R(s, \pi(s))$ for $s \in \mathcal{S}\big]$
        $\mathbf{U}$ = $\left(\mathbf{I} - \gamma \mathbf{T} \right)^{-1}  \mathbf{R}$

        # check convergence
        # lambdas 
        $\mathcal{U}$ = $s$ -> $\mathcal{U}(s)$
        $\pi'$ = $s$ -> greedy_action$\left(\mathcal{S}, T, R, \mathcal{A}, \gamma, \mathcal{U}, s\right)$
        if all$\big(\pi(s)$ == $\pi'(s)$ for $s \in \mathcal{S}\big)$:
            break
        $\pi$ = $\pi'$
    return $\pi$
```

# Value iteration

**Value iteration** is an alternative to policy iteration that updates the value function directly (instead of updating it through the policy).
It starts with any bounded $\lvert \mathcal{U}(s) \rvert < \infty$, e.g. $\mathcal{U}(s) = 0$, and improves it using the **Bellman equation**

$$
    \mathcal{U}_{k+1}(s) = \max_a \left( R(s, a)  + \gamma \sum_{s' \in \mathcal{S}} T(s' \mid s, a)\, \mathcal{U}_k(s') \right)
$$

This is called **backup**.

```
def backup$\left(R, \mathcal{A}, \mathcal{S}, \mathcal{U} \right)$:
    return $\max_{a \in \mathcal{A}} \left( R(s, a)  + \gamma \sum_{s' \in \mathcal{S}} T(s' \mid s, a)\, \mathcal{U}(s') \right)$
```

As already mentioned this is guaranteed to converge and the optimal policy is guaranteed to satisfy

$$
    \mathcal{U}^*(s) = \max_a \left( R(s, a)  + \gamma \sum_{s' \in \mathcal{S}} T(s' \mid s, a)\, \mathcal{U}^*(s') \right)
    \label{eq:optimal_policy}
$$

That is to say $\mathcal{U}^*(s)$ is a **fixed-point** of the Bellman equation.

```
def value_iteration$\big(R, T, \mathcal{A}, \mathcal{S}, \gamma,$k_max=100$\big)$:
    $\mathcal{U}_1$ = 0
    for k = 1:k_max
        $\mathcal{U}_{k+1}$ = $\big[$backup$\left(R, \mathcal{A}, \mathcal{S}, \mathcal{U}_k \right)$ for $s \in \mathcal{S}\big]$
    $\pi$ = $s$ -> greedy_action$\left(\mathcal{S}, T, R, \mathcal{A}, \gamma, \mathcal{U}_{\tt{k\_max}+1}, s\right)$
    return $\pi$
```

Note that we could also terminate value iteration conditional on $\lVert \mathcal{U}_{k+1} - \mathcal{U}_k \rVert _{\infty}$[^4], called the **Bellman residual**.
A Bellman residual of $\delta$ guarantees that the current iteration is within $\varepsilon = \delta \gamma/(1-\gamma)$ of the optimal value function $\mathcal{U}^\*$.
Similarly the **policy loss** $\lVert \mathcal{U}^\pi - \mathcal{U}^* \rVert _{\infty}$ bounds the deviation of the total reward obtained under the policy extracted from value iteration $\pi$; policy loss is bounded by $2\varepsilon$.

# Bonus: Linear Program (LP) Formulation

Finding the optimal policy can be reformulated as a **linear program**.
Begin by replacing the equality in equation $\eqref{eq:optimal_policy}$ with a set of inequality constraints and a minimization object

$$
\begin{aligned}
    \text{minimize}\quad &\sum_{s \in \mathcal{S}} \mathcal{U}(s) \\
    \text{subject to}\quad &\mathcal{U}(s) \geq \max_a \left( R(s, a)  + \gamma \sum_{s' \in \mathcal{S}} T(s' \mid s, a)\, \mathcal{U}(s') \right) \quad \text{(for all $s$)}\\
\end{aligned}
$$

Intuitively the minimization objective induces/encourages equality.
The $\max_a$ is a nonlinear constraint; it can be replaced by a set of linear constraints

$$
\begin{aligned}
    \text{minimize}\quad &\sum_{s \in \mathcal{S}} \mathcal{U}(s) \\
    \text{subject to}\quad &\mathcal{U}(s) \geq R(s, a)  + \gamma \sum_{s' \in \mathcal{S}} T(s' \mid s, a)\, \mathcal{U}(s') \quad \text{(for all $s,a$)}\\
\end{aligned}
$$

This is therefore a linear program because both the objective and constraints are linear in the variables $\,\mathcal{U}(s)$.

## Linear Systems with Quadratic Reward

The Bellman equation[^6] for continuous, vector-valued states and actions is

$$
\mathcal{U}_{h+1}(\vec{s}) = \max_\vec{a} \left( R(\vec{s}, \vec{a})  + \int\limits_{\vec{s}' \in \mathcal{S}} T(\vec{s}' \mid \vec{s}, \vec{a})\, \mathcal{U}_h(\vec{s}')\d\vec{s}' \right)
\label{eqn:hjb}
$$

Note that here we're assuming finite horizon and no discounting.
In general this is difficult to solve.
On the contrary, if a problem has **linear dynamics** and a **quadratic reward** then the optimal policy can be computed in closed form;
a problem has linear dynamics if 

$$
    \vec{s}' = \vec{T}_\vec{s} \vec{s} + \vec{T}_\vec{a} \vec{a} + \vec{w}
    \label{eqn:linear_dynamics}
$$

where 

$$
\begin{aligned}
    \vec{T}_\vec{s} &:= \mathbb{E}\left[ \vec{s}' \mid \vec{s} \right] \\
    \vec{T}_\vec{a} &:= \mathbb{E}\left[ \vec{s}' \mid \vec{a} \right] \\
\end{aligned}
$$

are matrices that represent the mean of the next state $\vec{s}'$ given $\vec{s}$ and $\vec{a}$ respectively, and $\vec{w}$ is zero mean, finite variance noise that is independent of both $\vec{s}, \vec{a}$ (e.g. multivariate Gaussian).
A reward function is quadratic if it can be written

$$
    R(\vec{s}, \vec{a}) = \vec{s}^\intercal \mathbf{R}_{\vec{s}} \vec{s} + \vec{a}^\intercal \mathbf{R}_{\vec{a}} \vec{a} 
    \label{eqn:linear_reward}
$$

where $\mathbf{R} _{\vec{s}}, \mathbf{R} _{\vec{a}}$ are matrices that determine the contributions of state and action to reward.
Further more $\mathbf{R} _{\vec{s}}, \mathbf{R} _{\vec{a}}$ should be negative semi-definite[^5] and negative definite, respectively; such a reward penalizes states and actions different from $\mathbf{0}$.
In control theory such a system is called a **linear quadratic regulator** (LQR).

Substituting eqns. $\eqref{eqn:linear_dynamics}$ and $\eqref{eqn:linear_reward}$ into the Bellman equation

$$
\mathcal{U}_{h+1}(\vec{s}) = \max_\vec{a} \left( \vec{s}^\intercal \mathbf{R}_{\vec{s}} \vec{s} + \vec{a}^\intercal \mathbf{R}_{\vec{a}} \vec{a} + \int p(\vec{w})\, \mathcal{U}_h(\vec{T}_\vec{s} \vec{s} + \vec{T}_\vec{a} \vec{a} + \vec{w})\d\vec{w} \right)
\label{eqn:linear_bellman}
$$

The optimal one-step lookahead function is 

$$
    \mathcal{U}_1 (\vec{s}) = \max_\vec{a} \left( \vec{s}^\intercal \mathbf{R}_{\vec{s}} \vec{s} + \vec{a}^\intercal \mathbf{R}_{\vec{a}} \vec{a} \right) = \vec{s}^\intercal \mathbf{R}_{\vec{s}} \vec{s}
$$

for which the optimal action is $\vec{a} = 0$ (since $\mathbf{R}_{\vec{a}}$ is negative semi-definite).
We now prove that $\mathcal{U}_h(\vec{s}) = \vec{s}^\intercal \vec{V}_h \vec{s} + q_h$ for a symmetric $\vec{V}_h$, with $\vec{V}_1 = \vec{R} _\vec{s}$ and $q_1 =0$.
Making this substitution into the right-hand side of eqn. $\eqref{eqn:linear_bellman}$

$$
\mathcal{U}_{h+1}(\vec{s}) = \vec{s}^\intercal \mathbf{R}_{\vec{s}} \vec{s} + \max_\vec{a} \left(  \vec{a}^\intercal \mathbf{R}_{\vec{a}} \vec{a} + \int p(\vec{w}) \Big( \left( \vec{T}_\vec{s} \vec{s} + \vec{T}_\vec{a} \vec{a} + \vec{w} \right)^\intercal \vec{V}_h \left( \vec{T}_\vec{s} \vec{s} + \vec{T}_\vec{a} \vec{a} + \vec{w} \right) + q_h  \Big)\, \d\vec{w} \right)
$$

Using $\int p(\vec{w}) \d \vec{w} = 1$ and $\int \vec{w} p(\vec{w}) \d\vec{w} = 0$ (zero mean) to simplify terms with a $q_h$ factor

$$
    \begin{aligned}
         \mathcal{U}_{h+1}(\vec{s}) &= \vec{s}^\intercal \mathbf{R}_{\vec{s}} \vec{s} + \vec{s}^\intercal \mathbf{T}_{\vec{s}}^\intercal \vec{V}_h \mathbf{T}_{\vec{s}} \vec{s} \\
         &\quad + \max_\vec{a} \Big( \vec{a}^\intercal \mathbf{R}_{\vec{a}} \vec{a} + 2 \vec{s}^\intercal \mathbf{T}_{\vec{s}}^\intercal \vec{V}_h \mathbf{T}_{\vec{a}} \vec{a} + \vec{a}^\intercal \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{a}} \vec{a}  \Big) \\ 
         &\quad + \int p(\vec{w}) \left( \vec{w}^\intercal \vec{V}_h \vec{w} \right)\,\d\vec{w} + q_h
    \end{aligned}
$$

Using 

$$
\begin{aligned}
    \nabla_{\vec{x}} (\vec{A}\vec{x}) &= \vec{A}^\intercal \\
    \nabla_{\vec{x}} (\vec{x}^\intercal\vec{A}\vec{x}) &= \left( \vec{A} + \vec{A}^\intercal \right)\vec{x}
\end{aligned}
$$

differentiating wrt $\vec{a}$ and setting equal to $\vec{0}$

$$
\begin{aligned}
    \vec{0} &= \left( \mathbf{R}_{\vec{a}} + \mathbf{R}_{\vec{a}}^\intercal \right)\vec{a} +  2 \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{s}} \vec{s} + \Big( \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{a}} + \left( \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{a}} \right)^\intercal    \Big)\vec{a} \\
    &= 2 \vec{R}_\vec{a} \vec{a} + 2 \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{s}} \vec{s} + 2 \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{a}} \vec{a}
\end{aligned}
$$

Using the fact that $\vec{R} _\vec{a} + \mathbf{T} _{\vec{a}}^\intercal \vec{V}_h \mathbf{T} _{\vec{a}}$ is negative definite and therefore invertible we obtain the optimal action

$$
    \vec{a} = - \left( \vec{R} _\vec{a} + \mathbf{T} _{\vec{a}}^\intercal \vec{V}_h \mathbf{T} _{\vec{a}}\right)^{-1} \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{s}} \vec{s} 
$$

and substituting into $\,\mathcal{U} _{h+1}(\vec{s})$ produces $\,\mathcal{U} _{h+1}(\vec{s}) = \vec{s}^\intercal \vec{V} _{h+1} \vec{s} + q _{h+1}$ with

$$
\vec{V}_{h+1} = \vec{R}_\vec{s} + \mathbf{T} _{\vec{s}}^\intercal \vec{V}_h^\intercal \mathbf{T}_{\vec{s}} - \left(  \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{s}} \right)^\intercal \left( \vec{R} _\vec{a} + \mathbf{T} _{\vec{a}}^\intercal \vec{V}_h \mathbf{T} _{\vec{a}}\right)^{-1} \left(  \mathbf{T}_{\vec{a}}^\intercal \vec{V}_h \mathbf{T}_{\vec{s}} \right)
\label{eqn:ricatti}
$$

and

$$
q_{h+1} = \sum_{i=1}^h \int p(\vec{w}) \left( \vec{w}^\intercal \vec{V}_i \vec{w} \right) \d \vec{w} = \sum_{i=1}^h \mathbb{E}_\vec{w} \left[ \vec{w}^\intercal \vec{V}_i \vec{w} \right]
$$

If $\vec{w} \sim \mathcal{N}(\vec{0}, \vec{\Sigma})$

$$
q_{h+1} = \sum_{i=1}^h \operatorname{Tr} \left( \vec{\Sigma} \vec{V}_i \right)
$$

Equation $\eqref{eqn:ricatti}$ is called the [discrete-time Ricatti equation](https://en.wikipedia.org/wiki/Algebraic_Riccati_equation).
Note that the optimal action is independent of $\vec{w}$ but the variance of $\vec{w}$ does affect the expected utility through $q_{h+1}$.


# Footnotes

[^1]: Capital letters $$S_t, A_t, R_t$$ stand for random variables, of which $$s_t, a_t, r_t$$ are samples.
[^2]: A contraction mapping on a metric space $$(M, d)$$ is a function $$f$$ from $$M$$ to itself, with the property that there is some nonnegative real number $$\varepsilon$$ such that $$0 \leq \gamma < 1$$ and for all $$x,y$$ in $$M$$ it's the case that $$d(f(x),f(y))\leq \varepsilon\,d(x,y)$$.
[^3]: Dynamic programming refers to simplifying a complicated problem by breaking it down into simpler sub-problems in a recursive manner. The relationship between the larger problem and the sub-problems is described by the [Bellman equation](https://en.wikipedia.org/wiki/Bellman_equation).
[^4]: Infinity norm is defined $\lVert \mathbf {x} \rVert _{\infty } := \max \left(\lvert x_1 \rvert, \ldots, \lvert x_n \rvert \right)$.
[^5]: $M{\text{ negative-definite}} \iff x^{\textsf {T}}Mx<0{\text{ for all }}x\in \mathbb {R} ^{n}\setminus \mathbf {0}$ and $M{\text{ negative semi-definite}}\iff x^{\textsf {T}}Mx\leq 0{\text{ for all }}x\in \mathbb {R} ^{n}$.
[^6]: With continuous parameters this is known as the [Hamilton–Jacobi–Bellman equation](https://en.wikipedia.org/wiki/Hamilton%E2%80%93Jacobi%E2%80%93Bellman_equation).