---
layout: post
title: Non-linear consensus protocols 
published: true
use_math: true
excerpt_separator: <!--more-->
tags: [distributed-systems, math]
---

This is a summary of [Non-linear protocols for optimal distributed consensus in networks of dynamic agents](https://www.sciencedirect.com/science/article/pii/S0167691106000971).

# Definitions

* $\Gamma = \\{1, \dots, n\\}$ is a set of agents/players/nodes/vertices and $G = (\Gamma, E)$ is a fixed (in time) undirected, connected[^1], network describing the connections between vertices $i \in \Gamma$, where $E \subset \Gamma \times \Gamma$ is the edge set. 
* A *neighborhood* of a vertex $i$ is the set of all vertices $j$ for which there is a single edge connecting $i,j$, that is to say $N_i := \\{j \mid (i,j) \in E\\}$. <!--more-->

    <p align="center">
    <img src="/images/nonlinear_consensus/graph.png" width="350"/>
    </p>

* Let $x_i(t)$ be the state of the agent $i$ at time $t$, then $x_i$ evolves according to a *distributed* and *stationary* control policy $u_i$, if $\dot{x}_i = u_i (x_i, \vec{x} _{N_i})$, where $\vec{x} _{N_i}$ are the states of $x_i$'s neighbors. Note, the control policy is distributed because of neighborhood dependency and stationary because of lack of explicit dependence on time. The *protocol* of the network is the collection of controls $\vec{u}(\vec{x}) := (u_i (x_i, \mathbf{x} _{N_i}))$ for all $i \in \Gamma$.
* The *agreement function* $\chi: \R^n \rightarrow \R$ is any continuous, differentiable function which is permutation invariant, i.e.

  $$\chi(x_1, \dots, x_n) = \chi(x_{\sigma(1)}, \dots, x_{\sigma(n)})$$

  for any permutation $\sigma$ on the vertex set $\Gamma$.

* To *reach consensus* on a *consensus value* $\chi(\vec{x}(0))$ means 

  $$ \lim_{t\rightarrow \infty}  \vec{x}(t) = \chi(\vec{x}(0))\vec{1} $$
  
  where $\vec{1} := (1,1, \dots, 1)$.

# The consensus problem

Given a network $G$ of agents and agreement function $\chi$, the *consensus problem* is to design a protocol $\vec{u}$ such that consensus is reached for any consensus value $\chi(\vec{x}(0))$.
A protocol is a *consensus protocol* if it is the solution to a consensus problem.
Since we're interested in agents reaching consensus on values $\chi(\vec{x}(0))$ that are functions of the whole system we further restrict $\chi$ such that

$$
    \min_{i\in \Gamma} (x_i) \leq \chi(\vec{x}) \leq \max_{i\in \Gamma} (x_i)
    \label{eqn:minmax}
$$

for $\vec{x} \in \R^n$.


We now prove some properties that consensus protocols must have and then give some nontrivial examples of consensus protocols.

## Time-invariance of $\chi$

<div class="lemma">

<b>Lemma 1</b>: Let $\vec{u}$ be a stationary consensus protocol.
Then $\chi(\vec{x}(t))$ is stationary, i.e. $\chi(\vec{x}(t)) = \chi(\vec{x}(0))$ for all $t > 0$.

</div>

<p></p>
<div class="proof">
<b>Proof</b>: By assumption $\vec{x}(t) \rightarrow \chi(\vec{x}(0))\vec{1}$. 
Stationary $\vec{u}$ is equivalent to autonomous and therefore, if $\vec{x}(t)$ is a solution then $\vec{y}_s(t) := \vec{x}(t+s)$ (with $\vec{y}_s(0) := \vec{x}(s)$) is also a solution.
For such $\vec{y}_s$ we also have $\vec{y}_s(t) \rightarrow \chi(\vec{y}_s(0))\vec{1}$ i.e.

$$
    \lim_{t\rightarrow \infty} \vec{y}_s(t) = \chi(\vec{y}_s(0)\vec{1}) = \chi(\vec{x}(s))
$$

But since both $\vec{y}_s, \vec{x}$ converge to the same limit we must have $\chi(\vec{x}(s)) = \chi(\vec{x}(0))$ for all $s$.
</div>

Note that by Lemma 1 we have that $\chi(\chi(\vec{x}(0))\vec{1}) = \chi(\vec{x}(0))$.
In fact, by setting $y = \lambda \vec1$ in eqn. ($\ref{eqn:minmax}$), we have that $\lambda \vec{1}$ is a fixed point of $\chi$ for any $\lambda \in \R$, i.e.

$$
\lambda \leq \chi(\lambda \vec{1}) \leq \lambda \Rightarrow \chi(\lambda \vec{1}) = \lambda
$$

With Lemma 1 in-hand we consider what the necessary properties of $\vec{u}$ are:

$$
\begin{aligned}
    \ddd{\chi(\vec{x}(t))}{t} &= \nabla_{\vec{x}}\chi \cdot \dot{\vec{x}} \\
    &= \sum_{i \in \Gamma} \pdd{\chi}{x_i}\dot{x}_i \\ 
    &= \sum_{i \in \Gamma} \pdd{\chi}{x_i} u_i  = 0\\ 
\end{aligned}
$$

Thus, a consensus protocol must satisfy $\nabla_{\vec{x}}\chi \cdot \vec{u} = 0$.
For example, with $\chi(\vec{x}) = \min_{i\in \Gamma} x_i$, a suitable $\vec{u}$ is

$$
    u_i = h \left( x_i, \min_{j\in N_i} x_j \right)
$$

where $h(x,y) = 0$ when $x = y$.
In this instance $\nabla_{\vec{x}} \chi \neq 0$ only when $x_i = \min_{j\in N_i} x_j$ but this case is taken care by definition.

Henceforth, we assume further structure for the agreement function:

$$
    \chi(\vec{x}) \equiv f \left( \sum_{i\in \Gamma} g(x_i) \right)
$$

with $f,g: \R \rightarrow \R$ and $g' \neq 0$.
Note that $p$-means

$$M_{p}(x_{1},\dots ,x_{n})=\left(\frac  {1}{n}\sum _{i=1}^{n}x_{i}^{p}\right)^{\frac  {1}{p}}$$

satisfy this assumption.

<div class="theorem">
<b>Theorem 1</b>: The following protocol

$$
    u_i (x_i, \mathbf{x} _{N_i}) := \frac{1}{g'} \sum_{j \in N_i} \phi(x_j, x_i)
    \label{eqn:protocol}
$$

with $g' \neq 0 $, induces time-invariance in $\chi$ if $\phi$ is antisymmetric, i.e. $\phi(x_j, x_i) = -\phi(x_i, x_j)$.
</div>

<p></p>

<div class="proof">
<b>Proof</b>:

$\chi$ is time-invariant if $\sum_{i\in \Gamma} g(x_i)$ is.
This is equivalent to

$$
\begin{aligned}
    \sum_{i \in \Gamma} \ddd{g(x_i(t))}{t} &= \sum_{i \in \Gamma} \ddd{g(x_i)}{x_i} \dot{x}_i \\ 
    &= \sum_{i \in \Gamma} g' u_i = 0 \\
\end{aligned}
$$

Finally, since $\phi$ is antisymmetric and the graph defining the network is undirected, we have that 

$$
\sum_{i \in \Gamma} g' u_i =  \frac{1}{g'} \sum_{i \in \Gamma} g' \sum_{j \in N_i} \phi(x_j, x_i) = 0
$$
</div>

Consider $\phi(x_j, x_i) := \alpha \cdot (x_j - x_i)$.
The $p$-mean is invariant under protocol

$$
    u_i (x_i, \vec{x} _{N_i}) :=  \frac{x_i^{1-p}}{p} \sum_{j \in N_i} \phi(x_j, x_i) = \alpha\cdot  \frac{x_i^{1-p}}{p} \sum_{j \in N_i} (x_j - x_i)
$$


## Convergence of $\chi$

Owing to time-invariance of $\chi$, if the system converges, it will converge to $\chi(\vec{x}(0))\vec{1}$. 
But it does not necessarily converge.
In this section we prove that the system converges, for any agreement function $\chi$ and initial state $\vec{x}(0)$, when $g$ is strictly increasing and the function $\phi$ is defined

$$
    \phi(x_j, x_i) := \alpha \phi(\theta(x_j) - \theta(x_i))
$$

where $\alpha > 0 $ and $\phi$ is continuous, locally Lipschitz[^2], odd and strictly increasing, and $\theta$ is differentiable with $\theta'$ locally Lipschitz and strictly positive.
Thus, the protocol ($\ref{eqn:protocol}$) becomes

$$
    u_i (x_i, \mathbf{x} _{N_i}) := \frac{\alpha}{g'} \sum_{j \in N_i} \phi\left(\theta(x_j) - \theta(x_i)\right)
    \label{eqn:protocol2}
$$

First we study the equilibria[^3] of the system.

<p class="lemma">
<b>Lemma 2</b>: Let $G$ be a network and $\vec{u}$ be a protocol with components defined by eqn. ($\ref{eqn:protocol2}$).
Then all equilibria of the network are of the form $\lambda \vec{1}$ and if $\vec{x}(t)$ converges to the equilibrium $\lambda_0 \vec{1}$ then $\lambda_0 = \chi(\vec{x}(0))$, for any initial state $\vec{x}(0)$.
</p>
<p></p>
<div class="proof">
<b>Proof</b>: First we show that an equilibrium $\vec{x}^* = \lambda\vec{1}$ and then $\lambda = \chi(\vec{x}(0))$.

<p></p>
<i>Sufficiency</i>: Assume $x_i = \lambda$, then $\phi\left(\theta(\lambda) - \theta(\lambda)\right) = 0$ since $\phi$ is odd and continuous.
Thus, $u_i = 0$ and thus $\vec{x}^* = \lambda \vec{1}$ is an equilibrium point.

<p></p>
<i>Necessity</i>: Assume an equilibrium $\vec{x}^* \neq \lambda \vec{1}$. 
We prove that this leads to the contradiction that $u_i < 0$ for some $i$ (which is a contradiction by definition of equilibrium).
Define $I$ as the set of agents have maximal state, i.e. $I := \{ i \in \Gamma \mid x_i^* \geq x_j^* \; \forall j \in \Gamma\}$.
Since $\vec{x}^* \neq \lambda\vec{1}$ it's the case that $I \subsetneq \Gamma$.
Then there exists an edge $(i,j) \in E$ such that $x_i^* \neq x_j^*$ and in particular we can choose an agent $i \in I$ such that there exists $k \in N_i$ with $x_k^* < x_i^*$.
Therefore, since $\theta$ is strictly increasing, for $j \in N_i$ we have that $\theta(x_j^*) - \theta(x_i^*) \leq 0$ with $\theta(x_k^*) - \theta(x_i^*) < 0$.
Then, since $\phi$ is odd and strictly increasing (odd and increasing means $\phi(t) < 0$ for $t < 0$)

$$
   \sum_{j\neq k \in N_i} \phi \left( \theta(x_j^*) - \theta(x_i^*)\right) + \left[\phi \left( \theta(x_k^*) - \theta(x_i^*)\right)\right] < 0
$$

because the sum has terms that are $\leq 0$ and the second term is $< 0$.
Finally, since $\alpha/g' \neq 0$, we have that $u_i < 0$, a contradiction.

<p></p>
<i>Convergence</i>: The foregoing arguments show that $\lambda\vec{1}$ is an equilibrium point.
Now we prove, by contradiction, that $\lambda = \chi(\vec{x}(0))$.
Assume $\lambda \neq \chi(\vec{x}(0))$, i.e. assume the system converges to a different equilibrium $\vec{x}^* = \lambda \vec{1} \neq \chi(\vec{x}(0))\vec{1}$.
Since $\chi$ has the fixed point property, we have that 

$$
    \chi(\vec{x}^*) = \chi(\lambda \vec{1})  = \lambda \neq \chi(\vec{x}(0))
$$

Thus $\chi$, under protocol ($\ref{eqn:protocol2}$), is not time-invariant (because it converges to something other than $\vec{x}(0)$) and that is a contradiction by Lemma 1.
</div>

We now prove prove that agents reach consensus on $\chi(\vec{x}(0))$ when $g$ is strictly increasing, i.e. $g' > 0$, using a Lyapunov function (see [appendix](#lyapunov-ляпуно́в-function)).

<div class="theorem">
<b>Theorem 2</b>: Consider a network of agents that implement a distributed and stationary protocol of the form of ($\ref{eqn:protocol2}$).
If $g$ is such that $g' > 0$ then the agents reach consensus on $\chi(\vec{x}(0))\vec{1}$ for any initial state $\vec{x}(0)$.
</div>
<p></p>
<div class="proof">
<b>Proof</b>: The proof proceeds by studying the stability of a proxy variable $\eta_i := g(x_i) - g(\chi(\vec{x}(0)))$.
Note that $\eta_i$ are bijective wrt $g$ and $\eta_i = 0 \iff \vec{x} = \chi(\vec{x}(0))\vec{1}$.
We prove that asymptotic stability of $\bm{\eta} = 0$ by using the Lyapunov function 

$$
    V(\bm{\eta}) := \frac{1}{2} \sum_{i \in \Gamma} \eta_i^2
$$
Trivially $V(\bm{\eta}) = 0$ iff $\bm{\eta} = 0$ and $V(\bm{\eta}) > 0$ for all $\bm{\eta} \neq 0$.
It remains to prove $\dot{V}(\bm{\eta}) < 0$ for all $\bm{\eta} \neq 0$:

$$
\begin{aligned}
     \dot{V}(\bm{\eta}) &= \sum_{i \in \Gamma} \eta_i \dot{\eta}_i \\
     &= \sum_{i \in \Gamma} \eta_i \ddd{g(x_i)}{x_i}\dot{x}_i \\
     &= \sum_{i \in \Gamma} \eta_i \ddd{g(x_i)}{x_i} u_i \\
     &= \sum_{i \in \Gamma} \eta_i \ddd{g(x_i)}{x_i} \left( \frac{\alpha}{g'} \sum_{j \in N_i} \phi\left(\theta(x_j) - \theta(x_i)\right) \right)  \\
     &= \alpha \sum_{i \in \Gamma} \eta_i \sum_{j \in N_i} \phi\left(\theta(x_j) - \theta(x_i)\right)  \\
     &= -\alpha \sum_{(i,j) \in E} \left( g(x_j) - g(x_i)\right) \phi\left(\theta(x_j) - \theta(x_i)\right)  \\
\end{aligned}
$$

Since $\alpha > 0 $, $g, \phi, \theta$ are strictly increasing we have for $x_j > x_i$

$$
    \begin{aligned}
         g(x_j) - g(x_i) &> 0 \\
         \theta(x_j) - \theta(x_i) &> 0 \\ 
         \phi\left(\theta(x_j) - \theta(x_i)\right) &> 0 
    \end{aligned}
$$

and hence $-\alpha\left( g(x_j) - g(x_i)\right) \phi\left(\theta(x_j) - \theta(x_i)\right) < 0$.
Symmetrically for $x_j < x_i$.
Hence, $\dot{V}(\bm{\eta}) < 0$ for all $\bm{\eta} \neq 0$.
</div>

# Mechanism design problem

Define an *individual objective function* for an agent $i$

$$
    J_i (x_i, \vec{x} _{N_i}, u_i) := \lim_{T \rightarrow \infty} \int_0^T \left( F(x_i, \vec{x} _{N_i}) + \rho u_i^2 \right)\d t
    \label{eqn:objective}
$$

where $\rho > 0$ and $F: \R \times \R^n \rightarrow \R$ is a non-negative *penalty function* that measures the deviation of agent $i$'s state $x_i$ from neighbors' states.
A protocol is *optimal* if each $u_i$ optimizes an agent's corresponding individual objective.

Consider a network $G  = (\Gamma, E)$ of agents.
The *mechanism design problem* is, for any agreement function $\chi$, determine a penalty $F$ such that there exists an optimal consensus protocol $\vec{u}$ with respect to $\chi(\vec{x}(0))$ for any initial state $x(0)$.

We first approximate the problem by a sequence of receding horizon problems wherein the controls are executed over one-step *action horizon* $\delta = t_{k+1}-t_k$.
Over this single step the neighbors' states are kept constant and at the beginning of the next step everyone optimizes wrt updates made in the previous step.
The approximation approaches the true solution as $\delta \rightarrow 0$.
Denote the predicted state of agent $i$ for the *planning period* $\tau \geq t_k$ by $\hat{x}_i(\tau, t_k)$ and the predicted states of agent $i$'s neighbors by $\hat{\vec{x}} _{N_i}(\tau, t_k)$.

The *receding horizon* problem is as follows: for all agents $i \in \Gamma$ and discrete time steps $t_k$, given initial states $x_i(t_0), \vec{x} _{N_i}(t_0)$ find

$$
    \hat{u}_i^* := \argmin  \hat{J}_i (\hat{x}_i, \hat{\vec{x}} _{N_i}, \hat{u}_i) 
$$

where

$$
    \hat{J}_i (\hat{x}_i, \hat{\vec{x}} _{N_i}, \hat{u}_i)  := \lim_{T \rightarrow \infty} \int_{t_k}^T \left( \hat{F}(\hat{x}_i, \hat{\vec{x}} _{N_i}) + \rho \hat{u}_i^2 \right)\d \tau
    \label{eqn:finitehorizon}
$$

subject to

$$
    \begin{aligned}
        \dot{\hat{x}}_i (\tau, t_k) &= \hat{u}_i(\tau, t_k) \\
        \dot{\hat{x}}_j (\tau, t_k) &= \hat{u}_j(\tau, t_k) \equiv 0 \quad \forall j \in N_i \\
        \hat{x}_i(t_k, t_k) &= x_i(t_k) \\ 
        \hat{x}_j(t_k, t_k) &= x_j(t_k) \quad \forall j \in N_i
    \end{aligned}
$$

Note that the assumption that all neighboring states are fixed during an action step implies that $\hat{\vec{x}} _{N_i}$ is constant (over the step) and so, over a particular time step $t_k$, eqn. ($\ref{eqn:finitehorizon}$) reduces to

$$
    \hat{J}_i (\hat{x}_i, \hat{u}_i)  := \lim_{T \rightarrow \infty} \int_{t_k}^T \left( \hat{F}(\hat{x}_i(\tau, t_k)) + \rho \hat{u}_i^2(\tau, t_k) \right)\d \tau
    \label{eqn:individualobjectivefunction}
$$

where I've suppressed dependence on $\hat{\vec{x}} _{N_i}$ because they're fixed over time step $t_k$.
Hence, the challenge is to determine $\hat{u}_i^2(\tau, t_k)$ that optimizes eqn. ($\ref{eqn:individualobjectivefunction}$).

We use Pontryagin's minimum principle (see the [appendix](#pontryagin-понтрягин-maximum-principle)); define the Hamiltonian


$$
    H(\hat{x}_i, \hat{u}_i, p_i) = L(\hat{x}_i, \hat{u}_i) + p_i \hat{u}_i
$$

where the *Lagrangian* $L := F(\hat{x}_i + \rho \hat{u}_i^2)$.
Then $H$ abides by the Pontryagin necessary conditions at the optimum $(\hat{x}_i^\*, \hat{u}_i^\*, p_i^\*)$:

$$
\begin{aligned}
    \pdd{H}{\hat{u}_i} = 0 \Rightarrow p_i = -2 \rho \hat{u}_i &\quad \text{optimality} \\  
    \dot{p}_i = -\pdd{H}{x_i} &\quad \text{multiplier} \\  
    \dot{\hat{x}}_i = -\pdd{H}{p_i} \Rightarrow \dot{\hat{x}}_i  = \hat{u}_i  &\quad \text{costate equation} \\  
    \frac{\p^2 H}{\p \hat{u}_i^2}\evalat{\hat{x}_i = \hat{x}_i^*, \hat{u}_i = \hat{u}_i^*, p_i = p_i^* } \geq 0 \Rightarrow \rho \geq 0 &\quad \text{minimality equation} \\ 
    H(\hat{x}_i^*, \hat{u}_i^*, p_i^*) = 0 &\quad \text{boundary}
\end{aligned}
$$

The last condition implies the Hamiltonian must be null along any optimal path $\hat{x}_i^\*(t)$ for all $t \geq 0$.
Pontryagin's minimum principle dictates necessary conditions for optimality that become sufficient if $F$ is convex.
<p></p>
<div class="theorem">
<b>Theorem 4</b>: Consider 

$$
    F(\hat{x}_i(\tau, t_k)) := \rho \left (\frac{1}{g'} \sum_{j \in N_i} \theta(x_j(t_k)) - \theta(\hat{x}_i(\tau, t_k)) \right)^2
    \label{eqn:penalty}
$$

where $g$ is increasing, $\theta$ is concave, and $(1/g')$ is convex.
Then 

$$
    \hat{u}_i^* := \frac{1}{g'} \sum_{j \in N_i} \theta(x_j (t_k) ) -  \theta(x_i (\tau)) 
    \label{eqn:optimalcontrol}
$$

is the unique optimal control that solves the mechanism design problem.
</div>
<p></p>
<div class="proof">

<b>Proof</b>: We first show that the problem is well posed by demonstrating a state $x_i^*$ reachable under a stationary control policy dependent on only local information $x_i, \vec{x} _{N_i}$ and for which the penalty ($\ref{eqn:penalty}$) and the control itself are null.
Note that $F = 0$ for $x_i^{*}$ such that 

$$
    \sum_{j \in N_i} \theta(x_j(t_k)) -  \theta(x_i^*) = 0 
$$

Therefore 

$$
    x_i^* := \theta^{-1} \left(\frac{1}{\lvert N_i \rvert} \sum_{j \in N_i} \theta(x_j(t_k)) \right)
$$

is such a trivial control policy that induces the objective ($\ref{eqn:individualobjectivefunction}$) to converge.

To show that $\hat{u}_i^*$ as stated in the theorem is optimal we show that it satisfies the conditions imposed by Pontraygin's minimum principle.
The costate equation and minimality condition are satisfied by assumption.
By differentiating the optimality condition and substituting into the multiplier condition we have

$$
    2 \rho \dot{\hat{u}}_i = \pdd{H}{\hat{x}_i}
    \label{eqn:twentythree}
$$

Differentiating both sides of costate equation we then have 

$$
    2 \rho \pdd{\hat{u}_i}{\hat{x}_i} \hat{u}_i = \pdd{H}{\hat{x}_i}
$$

and then integrating by parts and using the boundary condition we see that a solution eqn. ($\ref{eqn:twentythree}$) must satisfy

$$
    \rho \hat{u}_i^2 = F(\hat{x}_i)
$$

for which it obvious that 

$$
    \hat{u}_i(\tau, t_k) = \frac{1}{g'} \sum_{j \in N_i} \theta(x_j(t_k)) - \theta(\hat{x}_i(\tau, t_k))
$$

in fact does.
Finally to show convexity of $F(\hat{x}_i)$ let

$$
    \begin{aligned}
        F(\hat{x}_i) &:= \left( F_1(\hat{x}_i) \cdot F_2(\hat{x}_i) \right)^2 \\
        F_1(\hat{x}_i) &:= \left( \pdd{g}{x_i} \right)^{-1} \\
        F_2(\hat{x}_i) &:= \sum_{j \in N_i} \theta(x_j(t_k)) - \theta(\hat{x}_i(\tau, t_k))
    \end{aligned}
$$

Therefore $F$ is convex because $F_1$ is convex (because $1/g'$ is convex by assumption) and $F_2$ is convex (since $\theta$ is concave by assumption).

</div>

Note that the optimal control policy (eqn. ($\ref{eqn:optimalcontrol}$)) is a feedback policy wrt the state $\hat{x}_i$.

Taking $\delta \rightarrow 0$ we get that penalty function

$$
    F(x_i, \vec{x}_{N_i}) := \rho \left ( \left( \ddd{g}{x_i} \right)^{-1} \sum_{j \in N_i} \theta(x_j) - \theta(x_i) \right)^2
$$

and the optimal control law

$$
    u_i(x_i, \vec{x}_{N_i}) := \left( \ddd{g}{x_i} \right)^{-1} \sum_{j \in N_i} \theta(x_j) - \theta(x_i)
    \label{eqn:finalcontrol}
$$

# Code

The code is straightforward based on optimal control ($\ref{eqn:finalcontrol}$); e.g. with $F:= \left (\sum_{j \in N_i} (x_j - x_i) \right)^2$

```
Input: 
Network $G = (\Gamma, E)$ 
Initial states $x_i(t)$ 
Time step $\delta$

Execute:
for $k$ = $0, 1, \dots, T-1$:
    for $i \in \Gamma$:
        $t$ = $\delta \cdot k$
        $u_i$ = $\sum_{j \in N_i} (x_j(t) - x_i(t))$
        $x_i(t+\delta)$ = $u_i \cdot \delta$
return $x_i$
```

<!-- # Bonus
## Population protocols

https://www.cs.yale.edu/homes/aspnes/papers/podc04passive-dc.pdf

## Broadcast

https://arxiv.org/abs/2101.03780 -->

# Appendix

## Lyapunov (Ляпуно́в) function

This is mostly cribbed from [Wikipedia](https://en.wikipedia.org/wiki/Lyapunov_function).

In the theory of ordinary differential equations (ODEs), Lyapunov functions are scalar functions that may be used to prove the stability of an equilibrium of an ODE.

A Lyapunov function for an autonomous[^4] dynamical system

$$
{\begin{aligned}
f&:\mathbb {R} ^{n}\to \mathbb {R} ^{n}\\
{\dot {x}}&=f(x)
\end{aligned}}
$$

with an equilibrium point at $x=0$ is a scalar function $V:\mathbb {R} ^{n}\to \mathbb {R}$ that is continuous, has continuous first derivatives, is strictly positive, and for which $-\nabla {V}\cdot f$ is also strictly positive. 
Let $x^{*}=0$ be an equilibrium of the autonomous system $\dot{x}=f(x)$
and use the notation $\dot {V}(x)$ to denote the time derivative of the Lyapunov function $V$:

$$
\dot {V}(x)={\frac {\d}{\d t}}V(x(t))={\frac {\partial V}{\partial x}}\cdot {\frac {\d x}{\d t}}=\nabla V\cdot {\dot {x}}=\nabla V\cdot f(x)
$$

### Locally asymptotically stable equilibrium

If the equilibrium is isolated, the Lyapunov function $V$ is locally positive definite and the time derivative of the Lyapunov function is locally negative definite:

$$
{\dot {V}}(x)<0\quad \forall x\in {\mathcal {B}}\setminus \{0\}$$

for some neighborhood ${\mathcal {B}}$ of origin then the equilibrium is proven to be locally asymptotically stable.

### Stable equilibrium
If $V$ is a Lyapunov function, then the equilibrium is Lyapunov stable. 
The converse is also true.

### Globally asymptotically stable equilibrium

If the Lyapunov function $V$ is globally positive definite, radially unbounded, the equilibrium isolated and the time derivative of the Lyapunov function is globally negative definite:

$${\dot {V}}(x)<0\quad \forall x\in \mathbb {R} ^{n}\setminus \{0\}$$

then the equilibrium is proven to be globally asymptotically stable.

The Lyapunov-candidate function $V(x)$ is radially unbounded if

$$\|x\|\to \infty \Rightarrow V(x)\to \infty$$ 

This is also referred to as norm-coercivity.



## Pontryagin (Понтрягин) maximum principle

This is mostly cribbed from [Wikipedia](https://en.wikipedia.org/wiki/Pontryagin%27s_maximum_principle#Formal_statement_of_necessary_conditions_for_minimization_problem).

The Pontryagin maximum principle states that it is necessary for any optimal control and optimal state trajectory to solve the so-called *Hamiltonian* system (which is a two-point boundary value problem) plus a maximum condition of the control Hamiltonian. These necessary conditions become sufficient under certain convexity conditions on the objective and constraint functions.

Take $x$ to be the state of the dynamical system with control $u$, the constraints are

$$
\begin{aligned}
    \dot{x} &= f(x,u) \\
    x(0) &= x_{0} \\
    u(t) &\in {\mathcal  {U}}\\
    t &\in [0,T]
\end{aligned}
$$

where ${\mathcal {U}}$ is the set of admissible controls and $T$ is the terminal (i.e., final) time of the system. 
The control $u \in \mathcal{U}$ must be chosen for all $t\in [0,T]$ to minimize the objective functional $J$ which is defined by the application and can be abstracted as

$$J=\Psi (x(T))+\int _{0}^{T}L(x(t),u(t))\,dt$$

The constraints on the system can be adjoined to the Lagrangian $L$ by introducing time-varying Lagrange multiplier vector $\lambda$ , whose elements are called the *costates* of the system. 
This motivates the construction of the Hamiltonian $H$ defined for all $t\in [0,T]$ by:

$$
H(x(t),u(t),\lambda (t),t)=\lambda^\intercal (t)f(x(t),u(t))+L(x(t),u(t))
$$

Pontryagin's minimum principle states that the optimal state trajectory $x^\*$, optimal control $u^\*$, and corresponding Lagrange multiplier vector $\lambda^\*$ must minimize the Hamiltonian $H$ so that

$$
H(x^{*}(t),u^{*}(t),\lambda ^{*}(t),t)\leq H(x^{*}(t),u,\lambda ^{*}(t),t)
$$

for all time $t\in [0,T]$ and for all permissible control inputs $u \in \mathcal{U}$. It must also be the case that

$$
\Psi _{T}(x(T))+H(T)=0
$$

Additionally, the costate equations

$$
\begin{aligned}
    -{\dot {\lambda }}^{\intercal}(t) &={\frac {\partial }{\partial x}} H(x^{*}(t),u^{*}(t),\lambda (t),t) \\
    &= \lambda ^{\intercal}(t)f_{x}(x^{*}(t),u^{*}(t))+L_{x}(x^{*}(t),u^{*}(t)) 
\end{aligned}
$$

must be satisfied. 
If the final state $x(T)$ is not fixed (i.e., its differential variation is not zero), it must also be that the terminal costates are such that

$$
\lambda ^{\rm {T}}(T)=\Psi _{x}(x(T))
\label{eqn:four}
$$

Note that eqn. ($\ref{eqn:four}$) only applies when $x(T)$ is free. If it is fixed, then this condition is not necessary for an optimum.

These four conditions are the necessary conditions for an optimal control. 
If the Lagrangian is convex then they become sufficient conditions as well.




# Footnotes

[^1]: *Undirected* means $(i,j) \in E \Rightarrow (j,i) \in E$ and *connected* means there's a path $(i, k_1),\dots,(k_r, j)$ from any vertex $i$ to any other vertex $j$.
[^2]: For two metric spaces $(X, d_X)$ and $(Y, d_Y)$, a function $f : X \rightarrow Y$ is called *Lipschitz continuous* if there exists a real constant $K \geq 0$ such that, for all $x_1$ and $x_2$ in $X$ 

    $$d_{Y}(f(x_{1}),f(x_{2}))\leq Kd_{X}(x_{1},x_{2})$$

    A function $f$ is called *locally Lipschitz continuous* if for every $x$ in $X$ there exists a neighborhood $U$ of $x$ such that $f$ restricted to $U$ is Lipschitz continuous.

[^3]: States $\vec{x}$ such that $u_i = 0$ for all $i \in \Gamma$.
[^4]: An autonomous system or autonomous differential equation is a system of ordinary differential equations which does not explicitly depend on the independent variable.