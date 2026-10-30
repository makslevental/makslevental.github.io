---
layout: post
title: Covariant derivatives
published: true
excerpt_separator: <!--more-->
tags: [math, differential-geometry]
---

Covariant derivatives are a means of differentiating vectors relative to vectors. First we cover formal definitions of tangent vectors and then proceed to define a means to "covariantly differentiate".

<!--more-->

# Tangent vectors as derivations
The most general definition of a vector tangent to a manifold involves *derivations*.
$$
\newcommand{\R}{\mathbb{R}}
\newcommand{\T}{\mathcal{T}}
\newcommand{\vec}{\mathbf}
\newcommand{\parens}[1]{\left(#1 \right)}
\newcommand{\braces}[1]{\left\{#1 \right\}}
\newcommand{\angles}[1]{\langle #1 \rangle}
\newcommand{\d}{\text{d}}
\newcommand{\dd}[1]{\frac{\d}{\d #1}}
\newcommand{\ddd}[2]{\frac{\d #1}{\d #2}}
\newcommand{\pd}[1]{\frac{\partial}{\partial #1}}
\newcommand{\p}{\partial}
\newcommand{\pdd}[2]{\frac{\partial #1}{\partial #2}}
\newcommand{\evalat}[1]{\Big|_{#1}}
$$

Let $M$ be a smooth manifold; every **point** $p \in M$ has a neighborhood $U \subset M$ that can be mapped smoothly[^1] to $\R^n$ for some $n$ (the dimension of the manifold). 
**Therefore each $p$ can be identified with its coordinates**[^2] $\phi(p) = \parens{x^1(p), \dots, x^n(p)}$ where $x^i(p) \in \R$.

Associated with each point is the *tangent space* $T_p M$. 
Elements of the tangent space are called *tangent vectors* and can be intuitively visualized as arrows tangent to the manifold at that point; this can be made rigorous by way of *directional derivatives*.
Let $c(t) = \parens{p^1 +t v^1, \dots, p^n +t v^n}$ be a parameterization of a line through the point $p$ in the direction of $\vec{v} := \parens{v^1, \dots, v^n}$; if $f \in C^{\infty}_p$ in a neighborhood of $p$ then the directional derivative of $f$ in the direction of $\vec{v}$ is defined

$$
    D_{\vec{v}} f := \lim_{t\rightarrow 0} \frac{f(c(t)) -f(p)}{t} = \dd{t} f(c(t)) \Big|_{t=0}
$$

By the chain rule

$$
    \begin{aligned}
        D_{\vec{v}} f &= \sum_{i=1}^{n} \pdd{f}{x^i} \Big|_p \ddd{c^i}{t} \Big|_{t=0} \\
        &=  \sum_{i=1}^{n} \ddd{c^i}{t} \Big|_{t=0} \pdd{f}{x^i} \Big|_p \\
        &=  \sum_{i=1}^{n} v^i \pdd{f}{x^i} \Big|_p
    \end{aligned}
$$

and hence the directional derivative in the direction of $\vec{v}$ is defined

$$
    D_{\vec{v}} := \sum_{i=1}^{n} v^i \pdd{}{x^i} \Big|_p
$$

This directional derivative gives a map between between vector spaces

$$
    D_{\vec{v}}: C^{\infty}_p \rightarrow \R
$$

that also satisfies the *Leibniz rule*

$$
    D_{\vec{v}}(f g) = (D_{\vec{v}}f) g + f (D_{\vec{v}}g)
$$

In general any linear map from $C^{\infty}_p \rightarrow \R$ is called a *derivation* and the set of all derivations is a vector space[^3].
So we can identify tangent vectors[^4] with a legitimate vector space spanned by the basis

$$
    \braces{\p_1, \dots, \p_n} := \braces{\pd{x^1} \evalat{p}, \dots, \pd{x^n} \evalat{p}}
$$

The point being that, while not as geometrically intuitive
as arrows, this generalizes to manifolds.

Alternative notation for directional derivative

$$
\vec{v}(f) := D_{\vec{v}} f
$$

# Connections

Invariably (pardon the pun) when doing physics you'll need derivatives of quantities. This prompts the question: how do you differentiate a vector field[^5]?
Suppose we have a vector field $\vec{w}(p) = \parens{w^i(p)}$ that varies smoothly with $p$.
Notice that each $w_i: M \rightarrow \R$ is a smooth function so it can be differentiated in a straightforward fashion: 


$$
\vec{v}(w^i) = D_{\vec{v}} w^i
$$

Collecting all of these into a column we get 

$$
\vec{v}(\vec{w}) = \begin{bmatrix}
     D_{\vec{v}} w^1 \\
     \vdots \\
     D_{\vec{v}} w^n
    \end{bmatrix} = \vec{J} \vec{v}
$$

<!-- \end{bmatrix} = {\frac {\partial (w^{1},..,w^{n})}{\partial (x^{1},..,x^{n})}} \vec{v} = \vec{J} \vec{v} -->

where $\vec{J}$ is the Jacobian of $\vec{w}$ as a map from $M$ to $\R^n$. 
This is called the *Euclidean connection*.
Alternatively in components

$$
    (\vec{v}(\vec{w}))^i = \vec{v}(w^i) = \sum_j v^j \p_j w^i
$$

Unfortuntely this doesn't generalize so we define abstract differentiation of one vector field with respect to another.

Define 

$$
    TM := \bigsqcup_{p \in M} T_p M
$$ 

as the *tangent bundle* of $M$; an element of the tangent bundle is of the form $(p, \vec{v})$ with $p \in M$ and $\vec{v} \in T_p M$.
In fact $TM$ has a smooth manifold structure[^6]; let $\pi: TM \rightarrow M$ be the bundle projection.
A *section* of $TM$ is a map $F:M \rightarrow TM$ is an assignment of a vector to every $p \in M$, i.e. vector field on $M$. Thus, a vector field is smooth if the section $F$ is a **smooth map between manifolds**.

Let $\mathcal{T}(M)$ denote the space of smooth sections of $TM$, i.e. the space of smooth vector fields on $M$, and define a *connection* as the map $\nabla: \mathcal{T}(M) \times \mathcal{T}(M) \rightarrow \mathcal{T}(M)$.
Written $(\vec{v},\vec{w}) \mapsto \nabla_{\vec{v}} \vec{w}$, the connection satisfies

1. $\nabla_{\vec{v}} \vec{w}$ is linear in $\vec{v}$ over $f,g \in C^{\infty}(M)$:

   $$
        \nabla_{f \vec{v}_1 + g \vec{v}_2} \vec{w} = f \nabla_{\vec{v}_1} \vec{w} + g \nabla_{\vec{v}_2} \vec{w}
   $$
2. $\nabla_{\vec{v}} \vec{w}$ is linear in $\vec{w}$ over $a,b \in \R$:

   $$
        \nabla_{\vec{v}} \parens{a \vec{w}_1 + b \vec{w}_2} = a \nabla_{\vec{v}}\vec{w}_1 + b \nabla_{\vec{v}}\vec{w}_2
   $$
3. For all $f \in C^{\infty}(M)$ the connection satisfies a product rule

   $$
        \nabla_{\vec{v}} \parens{f \vec{w}} = f \nabla_{\vec{v}} \vec{w} + (vf)\vec{w}
   $$

$\nabla_{\vec{v}} \vec{w}$ is also called the *covariant derivative* of $\vec{w}$ in the direction $\vec{v}$.

<!-- each element of the tangent space is the equivalence of class of curves through $p$ that agree on a neighborhood containing $p$ and  -->

## Christoffel symbols

Suppose we have a *local frame* $\braces{\vec{e}_i}$ on a manifold $M$[^9].
Since $\braces{\vec{e}_i}$ is a basis and $\nabla$ maps pairs of vector fields to a vector field we can, for each pair $i,j$, expand $\nabla _{\vec{e}_i} \vec{e}_j$ in terms of the same basis/frame

$$
    \begin{aligned}
         \nabla _{\vec{e}_i} \vec{e}_j &= \Gamma_{ij}^1 \vec{e}_1 + \cdots + \Gamma_{ij}^n \vec{e}_n \\
         &= \Gamma_{ij}^k \vec{e}_k
    \end{aligned}
$$

where the $\Gamma_{ij}^k$ expansion coefficients, are called *Christoffel symbols*.
Then for arbitrary vector fields $\vec{v} := v^i \vec{e}_i$ and $\vec{w} := w^j \vec{e}_j$ and by the product rule above

$$
    \nabla_{\vec{v}} \vec{w} = \nabla_{\vec{v}} \parens{w^j \vec{e}_j} = w^j \nabla_{\vec{v}} \vec{e}_j + {\vec{v} (w^j)} \vec{e}_j
$$

By linearity in $\vec{v}$ the first term can be rewritten

$$
    w^j \nabla_{\vec{v}} \vec{e}_j = w^j \nabla_{v^i \vec{e}_i} \vec{e}_j = v^i w^j \nabla_{\vec{e}_i} \vec{e}_j = v^i w^j \Gamma_{ij}^k \vec{e}_k
$$

Renaming dummy indices we get 

$$
    \nabla_{\vec{v}} \vec{w} = \parens{ v^i w^j \Gamma_{ij}^k + \vec{v}(w^k) } \vec{e}_k
$$

Notice that we recover the Euclidean connection by setting $\Gamma_{ij}^k=0$.

# Geodesics

Let $\gamma: I \rightarrow M$, where $I = [0,1]$, be a smooth curve; the *velocity* vector $\dot{\pmb{\gamma}}$ is defined as the push-forward[^7] $\gamma_{*}$ of 

$$
     \pd{t} \equiv \dd{t}
$$

for $T_t I$.
Writing $\gamma(t) := \parens{\gamma^1(t), \dots, \gamma^n(t)}$ in coordinates we get that

$$
    \dot{\pmb{\gamma}}(f) = \pdd{f}{\gamma^i} \pdd{\gamma^i}{t} = (\dot{\gamma}^i \partial_i)(f)
$$

Let $\mathcal{T}(\gamma)$ denote the space of vector fields along $\gamma$ (i.e. $\vec{v} \in T_{\gamma(t)}M$ for all $\vec{v}$).
Then it can be shown[^8] that any connection $\nabla$ on $M$ determines a *covariant derivative* $D_t \colon \T(\gamma) \to \T(\gamma)$ along $\gamma$ satisfying the properties 

1. Linearity for $a,b \in \R$: 

    $$
        D_t(a\vec{v} + b\vec{w}) = aD_t\vec{v} + bD_t\vec{w}
    $$
2. Product rule for $f \in C^\infty (I)$: 

    $$
        D_t(f\vec{v}) = \dot{f} \vec{v} + f D_t\vec{v}
    $$
3. If $\vec{v}$ can be extended to $\tilde{\vec{v}}$ in a neighborhood of $\gamma(t)$ then this covariant derivative equals the connection (in the neighborhood) with respect to the velocity of $\gamma$ (on $\gamma(t)$)

    $$
        D_t(\vec{v}) \equiv \nabla_{\dot{\pmb{\gamma}}} \tilde{\vec{v}}
    $$

Using uniqueness we can compute the coordinate representation of $D_t \vec{v}$. Let $\vec{v} = v^j \partial_j$; then by linearity and the product rule

$$
    D_t \vec{v} = D_t \parens{v^j \partial_j} = \dot{v}^j \partial_j + v^j D_t \partial_j
$$

where $\partial_j$ is the basis vector of/induced by $\gamma$.
Since $\partial_j$ extends to the coordinate basis for the manifold in a neigbhorhood of $\gamma(t)$, the second term becomes

$$
    \begin{aligned}
        v^j D_t \partial_j &= v^j \nabla_{\dot{\pmb{\gamma}}} \partial_j \\ 
        &= v^j \nabla_{\dot{\gamma}^i \partial_i} \partial_j \\ 
        &= v^j \dot \gamma^i \nabla_{ \partial_i} \partial_j \\ 
        &= v^j \dot \gamma^i \Gamma_{ij}^k \partial_k 
    \end{aligned}
$$

where the Christoffel symbols are with respect to $\partial_i$ (the basis along $\gamma$).
Thus 

$$
    D_t \vec{v} = \parens{\dot{v}^k + v^j \dot \gamma^i \Gamma_{ij}^k} \partial_k 
$$

Now define the *acceleration* of $\gamma$ to be 

$$
    D_t \dot{\pmb{\gamma}} = \nabla_{\dot{\pmb{\gamma}}}  \dot{\pmb{\gamma}}
$$

This might seem strange but it is owing to the fact that $\dot{\pmb{\gamma}} = \gamma_{*} (d/dt)$ and so it plays the role of the derivative with respect to time on $\gamma$.
Using the above, in local coordinates 

$$
    D_t \dot{\pmb{\gamma}} =  \parens{\ddot{\gamma}^k + \gamma^j \dot \gamma^i \Gamma_{ij}^k} \partial_k 
$$

A *geodesic* with respect to the connection $\nabla$ is a curve with zero acceleration, i.e. $D_t \dot{\pmb{\gamma}} \equiv 0$.
This is the case iff (in coordinates)

$$
    \ddot{\gamma}^k + \gamma^j \dot \gamma^i \Gamma_{ij}^k = 0
$$

which is a set of coupled second-order differential equations called the *geodesic equation(s)*.
For example, in the Euclidean connection (where $\Gamma_{ij}^k \equiv 0$) this reduces to the familiar 

$$
    \ddot{\gamma}^k = 0 
$$

with equally as familiar solution $\gamma(t) = \gamma(0) + \dot \gamma(0) t$, i.e. straight lines.
In general (as with most differential equations) there is no solution to the geodesic equation.

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
