---
layout: post
title: Levi-Civita
published: false
tags: [math, differential-geometry]
---

If a manifold is *Riemannian* (has a metric) then there's a unique connection (i.e. covariant derivative) that's compatible with that metric; the *Levi-Civita* connection is the unique connection that's compatible with the metric.

Let's start with a concrete example: consider the unit 2-sphere with poles removed and embedded in $\R^3$ 

$$
    S^2 =  \braces{ (x,y,z) \, \lvert \, x^2+y^2+z^2 = 1, z \neq 1,-1, (x,y,z) \in \R^3 }
$$

imbued with the canonical Euclidean metric $g = I$.
Consider $S^2$ the sphere with the poles removed and the *geographic coordinate system/chart* $F$ that maps $S^2$ to $\R^2$ 


$$
    \begin{aligned}
        F &: S^2 \rightarrow \R^2 \\
        (x,y,z) &\rightarrow (0, \pi) \times (0 , 2\pi) \\
        \varphi &:= \arctan \parens{\frac{y}{x}} \\
        \theta &:= \arccos \parens{\frac{z}{x^2 + y^2 + z^2}} \\
        &\,= \arccos(z)
    \end{aligned}
$$

and its inverse $F^{-1}$

$$
    \begin{aligned}
        F^{-1} &: \R^2 \rightarrow S'^2 \\
        x&=\sin \theta \,\cos \varphi \\
        y&=\sin \theta \,\sin \varphi \\
        z&=\cos \theta 
    \end{aligned}
$$

<p align="center">
  <img src="https://user-images.githubusercontent.com/5657668/83292047-73140380-a1b7-11ea-8407-4d0ded8ee4bb.png"/>
</p>

Define the coordinate basis vectors at point $p \in S^2$

$$
    \begin{aligned}
        \vec{e}_{\varphi}(p) := \pd{\varphi}\evalat{p} := \parens{F^{-1}}_* \pd{\varphi}\evalat{F(p)}
    \end{aligned}
$$


Here $\theta,\varphi$ are called *local coordinates*, with $\varphi$ being called the azimuthal angle and $\theta$ variously called polar angle, zenith angle, normal angle, or inclination angle.
They also correspond to latitude, longitude respectively.

# Foonotes


[^1]: A topological space $M$ is *locally Euclidean of dimension $n$*  if for every $p \in M$ there exists a neighborhood $U$ such that there is a $homeomorphism$ $\phi$ from $U$ **onto** an opensubset of $\mathbb{R}^n$. The pair $\left( U,\phi \colon U \rightarrow \R^n \right)$ is called a *chart*, with *U* being the *coordinate neighborhood* and $\phi$ the *coordinate system*.

[^2]: The sense here is akin to latitude and longitude coordinates on the earth: coordinates are a mapping from the spherical earth (a manifold $S^2$) to a rectilinear coordinate system $\R^2$.

[^3]: Loring Tu's An Introduction to Manifolds: Theorem 2.2.

[^4]: Tangent vectors $\iff$ directional derivatives $\iff$ derivations.

[^5]: The assignment of a vector from $T_p M$ to each $p \in M$.

[^6]: A *vector bundle* is a family of vector spaces parameterized by another space. A vector bundle consists of a *base space* $X$, a *total space* $E$, a continuous surjection (called the bundle projection) $\pi: E \rightarrow X$, and where for every $x \in X$ the *fiber* $\pi^{-1}(x)$ is a finite-dimensional vector space.

[^7]: Let $\phi: M \rightarrow N$ be a smooth map of smooth manifolds. The *differential* of $\phi$ at $x \in M$ is a linear map

    $$
        d\phi _{x}:T_{x}M\to T_{\phi (x)}N
    $$

    The application of $d\phi _{x}$ to a tangent vector $\vec{v} \in T_x M$ is the *pushforward* of $\vec{v}$ by $\phi$.
    Concretely

    $$
        (d\phi _{x}(\vec{v}))(f) = \vec{v} (f \circ \phi)
    $$

    If charts are chosen from both $M,N$ then $\phi$ is locally determined by a smooth map $\phi: U \rightarrow W$ on neighborhoods $U \subset \R^m, W \subset \R^n$ (with coordinates $\parens{u^i}, \parens{w^j}$ respectively).
    Then by the chain rule $d\phi _{x}$ has representation (i.e. coordinate basis representation)

    $$
        \begin{aligned}
            \parens{d\phi _{x} \parens{\pd{u^i}}}(f) &= \pd{u^i} \parens{f \circ \phi} \\
            &= \pdd{f}{\phi^j}\pdd{\phi^j}{u^i} \\
            &= \pdd{f}{w^j}\pdd{\phi^j}{u^i} \\
            &= \parens{\pdd{\phi^j}{u^i} \pd{w^j}} f
        \end{aligned}
    $$

    where we've used the coordinate representation of $w^j \equiv \phi^j \equiv w^j(\phi)$. 
    Hence

    $$
        \parens{d\phi _{x}}_i^j = \vec{J}
    $$
    
    Alternative notations for the pushforward are $D\phi ,\; \phi_*,\; \phi'$.

[^8]: Lee's Smooth Manifolds: Lemma 4.9

[^9]: A smoothly varying vector field such that at each point $p$ the set of tangent vectors $\braces{\vec{e}_i(p)}$ is a basis for the tangent space $T_p M$

<!-- [^1]: Assume a general, linear, second-order PDE in two variables $u(x,y)$

    $$
        Au_{xx}+2Bu_{xy}+Cu_{yy}+\cdots {\mbox{(lower order terms)}}=0,
    $$
    This form of the PDE resembles a conic section and naturally suggests a classification based on the value of the discriminant
    * $B^2 - A C < 0$: elliptic partial differential equation
    * $B^2 - A C = 0$: parabolic partial differential equation
    * $B^2 - A C > 0$: hyperbolic partial differential equation -->

<!-- [^2]: A good mnemonic is "low-co-row".
  
[^3]: Einstein summation convetion.

[^4]: A map from the vector space to the ground field that's linear in both of its arguments.

[^5]: Actually it's vector spaces; The *tensor product* $V \otimes W$ of two vector spaces $V$ and $W$ (over the same field) is itself a vector space, endowed with the operation of bilinear composition, denoted by $\otimes$, from ordered pairs in the Cartesian product $V \times W$ to $V \otimes W$ in a way that generalizes the outer product (quotienting). -->
