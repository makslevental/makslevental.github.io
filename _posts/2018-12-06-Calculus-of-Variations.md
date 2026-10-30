---
layout: post
title: Calculus of Variations
published: true
tags: [math, probability]
---

# Radon–Nikodym


A measure $\mu$  on Borel subsets of the real line is absolutely continuous with respect to Lebesgue measure $\lambda$  (in other words, dominated by  $\lambda$ ) if for every measurable set  $A$,  $\lambda(A) = 0$ implies $\mu(A)=0$. This is written as $ \mu \ll \lambda$.

If $ \nu \ll \mu $, then there is a measurable function $f:X\rightarrow [0,\infty )$, such that for any measurable set $ A\subseteq X$,

$$
 \nu (A)=\int _{A}f\,d\mu 
 $$
 
The function  $f$  is called the Radon–Nikodym derivative of $\nu$ with respect to $\mu$ and is denoted by  $\frac {d\nu }{d\mu }$.

# Riesz–Markov–Kakutani representation theorem

Let $X$ be a locally compact Hausdorff space. For any positive linear functional  $\psi$  on $C_c(X)$, the space of continuous compactly supported complex-valued functions on a locally compact Hausdorff space $X$, there is a unique regular Borel measure $\mu$ on $X$ such that

$$  \psi(f) = \int_X g(x) \, d \mu(x) \quad $$

for all $g$ in $C_c(X)$.

# Functional derivative

Given a manifold $M$ representing (continuous/smooth) functions $\rho$ (with certain boundary conditions etc.), and a functional $F$ defined as

$$F\colon M \rightarrow \mathbb{R} \quad \mbox{or} \quad F\colon M \rightarrow \mathbb{C} $$

let

$$

\begin{align}
 \lim_{\varepsilon\to 0}\frac{F[\rho+\varepsilon g]-F[\rho]}{\varepsilon} &= \left [ \frac{d}{d\epsilon}F[\rho+\epsilon g]\right ]_{\epsilon=0},
\end{align}

$$

where  $g$  is an arbitrary function. This is analogous to the directional derivative

$$
  \lim _{h\rightarrow 0}\frac {f(\mathbf {x} +h\mathbf {v} )-f(\mathbf {x} )}{h}
  
     = \left[\frac{d }{d \alpha}~f(\mathbf{v} + \alpha~\mathbf{u})\right]_{\alpha = 0}


$$

The quantity $\varepsilon g$ is called the variation of $\rho$. In other words,

$$ \psi: g \mapsto \left[\frac  {d}{d\epsilon }F[\rho +\epsilon g ]\right]_{\epsilon =0}$$

is a linear functional, so by the Riesz–Markov–Kakutani representation theorem, this functional is given by integration against some measure. Then  $ \delta F/\delta \rho (x)$ is defined to be the Radon–Nikodym derivative of this measure and therefore

$$
\psi(g) = \int g(x) \frac{\delta F}{\delta\rho(x)} \; dx 
$$

We think of the function $ \delta F/\delta \rho (x)$ as the gradient of $F$ at the point $\rho$ and

$ \int  g(x) \frac{\delta F}{\delta\rho(x)}\; dx $
as the directional derivative at point $\rho$ in the direction of $g$.

# Euler-Lagrange

Consider the functional

$$
J[f]=\int _{a}^{b}L[\,x,f(x),f\,'(x)\,]\,dx
$$

where $f'(x) \equiv df/dx$. If $f$ is varied by adding to it a function $\delta f$, and the resulting integrand $L(x, f +\delta f, f '+\delta f ′)$ is expanded in powers of $\delta f$, then the change in the value of $J$ to first order in $\delta f$ can be expressed as follows:

$$
 \delta J = \int_a^b  \frac{\delta J}{\delta f(x)} {\delta f(x)} \, dx \, . 
 $$
 
The coefficient of $\delta f(x)$, denoted as $\delta J/\delta f(x)$, is called the functional derivative of $J$ with respect to $f$ at the point $x$. For this example functional, the functional derivative is the left hand side of the Euler-Lagrange equation

$$
\frac {\delta J}{\delta f(x)} = \frac {\partial L}{\partial f} - \frac{d}{dx}\frac {\partial L}{\partial f'}
$$
