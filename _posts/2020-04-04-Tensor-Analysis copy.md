---
layout: post
title: Tensor analysis
published: true
tags: [math, differential-geometry]
---

<!-- In general theory of relativity (GR) the *Einstein field equations* relate the geometry of space-time with the distribution of matter within it. -->

$$
\newcommand{\vec}{\mathbf}
\newcommand{\d}{\text{d}}
\newcommand{\bm}{\pmb}
\newcommand{\pd}[1]{\frac{\partial}{\partial #1}}
\newcommand{\pdd}[2]{\frac{\partial #1}{\partial #2}}
$$

<!-- # Introduction

Einstein's field equations describe the curvature of space as a function of energy and momentum; they're a system of ten coupled, nonlinear, hyperbolic-elliptic partial differential equations[^1]. 
Typically the equations are expressed in tensor form as 

$$
    {\displaystyle R_{\mu \nu }-{\tfrac {1}{2}}Rg_{\mu \nu }+\Lambda g_{\mu \nu }={\frac {8\pi G}{c^{4}}}T_{\mu \nu }}
$$

where $R_{\mu \nu }$ is the Ricci curvature tensor, $R$ is the scalar curvature, $g_{\mu \nu }$ is the metric tensor, $\Lambda$ is the cosmological constant, $G$ is Newton's gravitational constant, $c$ is the speed of light in vacuum, and $T_{\mu \nu }$ is the stress–energy tensor. Each covariant (explained in the forthcoming) index $\mu, \nu$ can take on values $0,1,2,3$ thereby giving 16 different equations in principle, but it turns out each of the tensors is symmetric thereby reducing the number of unique equations to ten.

# Tensors -->

# Covariance and contravariance of vectors

## Intuition

Covariance and contravariance characterize how quantities (typically vectors) measured in some space transform when the space undergoes a change of basis or coordinate system. 
A *covariant* quantity has components that transform in the same way as the basis (to be clarified). 
A *contravariant* quantity has components that transform opposite of the basis (to be clarified). 

A physical example will illustrate the intuitive sense of the words: imagine a temperature $T$ as a function of position $x$ where position is measured in meters and temperature in degrees Fahrenheit:

$$
    T = f(x)
$$

Consider two quantities: 

1. displacement along the $x$-axis between positions (i.e. $\Delta x = x^2 - x^1$)
2. the derivative of $T$ with respect to $x$ at some $x^0$ (i.e. the gradient or the slope)

What happens to each quantity if we rescale the $x$-axis (i.e. change the coordinate system) to be in terms of kilometers instead of meters (i.e. scale the $x$-axis by 1000)?

1. any displacement will shrink by 1000 (i.e. will change opposite of the $x$-axis)
2. the gradient will become steeper by a factor of 1000 (i.e. will change in the same way as the $x$-axis) since, for example, 5 degrees per meter is the same as 5000 degrees per kilometer.

Hence displacement is a contravariant quantity and the gradient is a covariant quantity.

Some conventions:

1. Covariant vectors are written as rows[^2] of components with subscripts: $(\alpha_1, \alpha_2, \alpha_3)$
2. Contravariant vector are written as columns of components with superscripts:
   
   $$
        \begin{bmatrix}
            v^1 \\
            v^2 \\
            v^3 
        \end{bmatrix}
   $$
3. Expressions with repeated indices indicate a sum[^3]: $\alpha_i v^i = \sum_i \alpha_i v^i$

In general covariance and contravariance characeterize how components of vector transform under a change of basis; let $V$ be a vector space and let $\bm{e} := \left(\bm{x}_1, \dots, \bm{x}_n\right)$ and $\bm{e}' := \left(\bm{y}_1, \dots, \bm{y}_n\right)$ be bases for $V$.
Then $\bm{e}'$ is related to $\bm{e}$ (and vice-versa) by a change of basis i.e right multiplication by a change of basis matrix $A := \left(a_j^i\right)$

$$
    \begin{aligned}
        \bm{e}' &= \bm{e} \cdot A \\ 
        &= \left(a_1^i \bm{x}_i, \dots, a_n^i \bm{x}_i\right) \\
        
    \end{aligned}
$$

or terms of components $\bm{y}_j = a_j^i \bm{x}_i$.

## Contravariance

Let $$v = v_{\bm{e}}^i \cdot \bm{x}_{i}$$ be a vector where $v_{\bm{e}}^i$ are the components of the vector relative to the $\bm{e}$ basis.

If we write the components of $v$ as a column vector 

$$
        \bm{v}_{\bm{e}} = \begin{bmatrix}
            v_{\bm{e}}^i \\
            \vdots \\
            v_{\bm{e}}^n \\
        \end{bmatrix}
$$

we can omit indices and write 

$$
    v =  v_{\bm{e}}^i \cdot \bm{x}_i = \bm{e} \cdot \bm{v}_{\bm{e}}
$$

or in the $\bm{e}'$ basis

$$
    v =  \bm{e}' \cdot \bm{v}_{\bm{e'}}
$$

Equating the two and substituting $\bm{e}' = \bm{e} \cdot  A$

$$
\begin{aligned}
    \bm{e} \cdot \bm{v}_{\bm{e}} &=  \bm{e}' \cdot \bm{v}_{\bm{e}'} \\
    &= (\bm{e} \cdot A ) \cdot \bm{v}_{\bm{e}'}
\end{aligned}
$$

Comparing both sides we see that (since $A$ is a change of basis and therefore invertible)

$$
    \bm{v}_{\bm{e}'} = A^{-1} \cdot \bm{v}_{\bm{e}}
$$

where $A^{-1} := (\tilde{a}_j^i)$ is the inverse of the change of basis.

In components

$$
    v_{\bm{e}'}^i = \tilde{a}_j^i v_{\bm{e}}^j
$$

This then is the precise meaning of contravariance; because the components transform with the inverse of the change of basis $A^{-1}$ the components are said to *transform contravariantly* and the vector $v$ is said to a contravariant vector. 

## Covariance

A linear functional $\alpha$ on the vector space $V$ is a linear map from $V$ to $\mathbb{R}$.
Such a functional is represented in terms of its components with respect to the *dual basis* $\bm{f} := \left(\bm{u}^1, \dots, \bm{u}^n\right)$ (note the upper indices) which are defined by their action on the basis $\bm{e}$

$$
    \bm{u}^i (\bm{x}_j) = \delta_j^i
$$

where $\delta_j^i$ the Kronecker delta is defined

$$
 \delta_j^i := \begin{cases} 
  1 \text{ if } i = j \\
  0 \text{ otherwise}
\end{cases}
$$

The components of $\alpha$ with respect to the dual basis $\bm{f}$ can be seen to be $\alpha_i^{\bm{f}} := \alpha(\bm{x}_i)$.
Naturally, under a change of basis for $V$, i.e. $\bm{e} \rightarrow \bm{e}'$, the components of $\alpha$ also transform due to the change of basis $\bm{f} \rightarrow \bm{f}'$:

$$
    \begin{aligned}
        \alpha_i^{\bm{f}'} &:= \alpha(\bm{y}_i) \\
        &\;= \alpha( a_i^j \bm{x}_j) \\
        &\;= a_i^j  \alpha( \bm{x}_j) \\
        &\;= a_i^j  \alpha_j^{\bm{f}} 
    \end{aligned}
$$

Define $\bm{\alpha}^{\bm{f}} := \left(\alpha_1^{\bm{f}}, \dots, \alpha_n^{\bm{f}}   \right)$ to be the row vector of components of $\alpha$ and we can write the above index free as $\bm{\alpha}^{\bm{f}'} = \bm{\alpha}^{\bm{f}} \cdot A$.
This then is the precise meaning of covariance; because the components of linear functionals transform with $A$ (rather than $A^{-1}$) they are said to *transform covariantly* and $\alpha$ is said to be a covariant vector or just *covector*.

# Manifolds

Let $M$ be a $n$-dimensional manifold with an atlas of coordinate charts, i.e. overlapping coordinate systems. 
For a particular coordinate system $\{x^1, \dots, x^n\}$ the tangent space $TM_p$ at a point $p \in M$ has a basis comprised by partial derivatives with respect to those coordinate functions:

$$
    \bm{e} = \left\{ \pd{x^1}, \dots, \pd{x^n} \right\}
$$

In this context a basis is called a *frame*.

## Tangent vectors

If 

$$
    \bm{e}' = \left\{ \pd{y^1}, \dots, \pd{y^n} \right\}
$$

is another frame then the frame are related by the *Jacobian*

$$
    \mathbf{J} := \begin{bmatrix}{\dfrac {\partial y_{1}}{\partial x_{1}}}&\cdots &{\dfrac {\partial y_{1}}{\partial x_{n}}}\\\vdots &\ddots &\vdots \\{\dfrac {\partial y_{n}}{\partial x_{1}}}&\cdots &{\dfrac {\partial y_{n}}{\partial x_{n}}}\end{bmatrix}
$$

through its inverse

$$
    \bm{e}' = \bm{e} \cdot \mathbf{J}^{-1}
$$

This is evident by considering the chain rule

$$
    \pdd{f}{y^i} = \sum_i \pdd{f}{x^j} \pdd{x^j}{y^i}
$$

or 

$$
    \pd{y^i} =  \pdd{x^j}{y^i}\pd{x^j}
$$

It bears repeating: the basis for the tangent space transform with $\mathbf{J}^{-1}$.
A *tangent vector* $v$ is a linear combination of coordinate partials 

$$
    v =  v_{\bm{e}}^i \pd{x^i} = \bm{e} \cdot \bm{v}_{\bm{e}}
$$

Under a change in coordinate system $\bm{e} \rightarrow \bm{e}'$

$$
   \bm{e} \cdot \bm{v}_{\bm{e}} = \bm{e}' \cdot \bm{v}_{\bm{e}'} = \left( \bm{e} \cdot \mathbf{J}^{-1} \right) \cdot \bm{v}_{\bm{e}'}
$$

and hence 

$$
    \bm{v}_{\bm{e}'} = \mathbf{J} \cdot \bm{v}_{\bm{e}}
$$

i.e. the components of $\bm{v}_{\bm{e}}$ transform contravariantly.

## Differentials

For a particular coordinate system $\{x^1, \dots, x^n\}$ the cotangent space $TM_p^*$ at a point $p \in M$ has a dual basis comprised by differentials (also called *1-forms*) $$\;\bm{f} = \left\{\d x^1, \dots ,\d x^n  \right\}$$ defined by the relation

$$
    \d x^i \left(\pd{x_j}\right) = \delta_j^i
$$

The dual basis elements transform contravariantly:

$$
    \d y^i = \pdd{y^i}{x^j} \d x^j
$$

In opposition to the dual basis, the components of a 1-form $\alpha$ transform covariantly under a change of basis $\bm{f} \rightarrow \bm{f}'$ (induced by a change of basis $\bm{e} \rightarrow \bm{e}'$):

$$
    \begin{aligned}
        \alpha_i^{\bm{f}'} &:= \alpha \left(\pd{y_i}\right) \\
        &\;= \alpha \left(\pdd{x^j}{y^i}\pd{x^j}\right) \\
        &\;= \pdd{x^j}{y^i}  \alpha \left(\pd{x^j}\right) \\
        &\;= \pdd{x^j}{y^i}  \alpha_j^{\bm{f}} \\
    \end{aligned}
$$

Hence $\bm{\alpha}^{\bm{f}'} = \bm{\alpha}^{\bm{f}} \cdot \mathbf{J}^{-1}$ and therefore 1-forms transform covariantly.

# $n$-Tensors

Vectors can be combined[^5] to form higher rank tensors; the combination of two contravariant vectors $v,w$, sometimes denoted in a coordinate free fashion as $T := v \otimes w$ or in coordinates as $T^{mn} := v^m w^n$, is called a *rank 2* tensor or *2-tensor*.
Contravariant and covariant vectors can also be combined; the combination of a covariant $v$ and a contravariant $w$, denoted $T_m^n := v_m w^n$ is called a rank 2 *mixed tensor*. 
Note that the dimension of the tensor space is the product of the dimensions of the factor spaces, i.e. $\dim(V \otimes W) = \dim(V) \times \dim(W)$ but the *arity* of the tensor is the number of factor spaces. 
The preceding constructions naturally extend to higher arities. 
Incidentally a scalar is a rank 0.

Higher rank tensors transforms according to how their factors transform

$$
    \begin{aligned}
        T^{mn}_{\bm{e}'} &:= v_{\bm{e}'}^m w_{\bm{e}'}^n \\
        &\;= \sum_{i} \pdd{y^m}{x^i} v_{\bm{e}}^i \sum_{j} \pdd{y^n}{x^j} w_{\bm{e}}^j  \\ 
        &\;= \sum_{ij} \pdd{y^m}{x^i}  \pdd{y^n}{x^j} v_{\bm{e}}^i w_{\bm{e}}^j  \\ 
        &\;= \sum_{ij} \pdd{y^m}{x^i}  \pdd{y^n}{x^j} T^{ij}_{\bm{e}}  \\ 
    \end{aligned}
$$

and so we see that $T^{ij}_{\bm{e}}$ transforms with two applications of $\mathbf{J}$ and so it is twice contravariant (hence the two contravariant indices).
Analogously a covariant rank 2 tensor transforms with two applications of $\mathbf{J}^{-1}$

$$
        T_{mn}^{\bm{e}'} = \pdd{x^i}{y^m}  \pdd{x^j}{y^n} T_{ij}^{\bm{e}}
$$

## Metric tensors

A *metric tensor* (or just metric) is a bilinear form[^4] $g: V \times V \rightarrow K$. 
Since 1-forms map vectors to numbers it should be no surprise that a metric is the tensor product of 1-forms:

$$
    g := g_{mn} \d x^m \d x^n \\
$$

For intuition consider $n$-dimensional Pythagoras' theorem

$$
    \begin{aligned}
        \d s^2 &:= \left(\d x^1\right)^2 + \left(\d x^2\right)^2 + \cdots + \left(\d x^n\right)^2 \\
        &\;= \d x^m \d x^m \\ 
        &\;= \d x^m \d x^n \delta_{mn} \\ 
    \end{aligned}
$$

where $\delta_{mn}$ is called the *flat* metric (non-zero terms only on the diagonal); it's exactly the non-flat metrics that are interesting in GR (non-zero terms off the diagonal).

How does the metric transform under a change of coordinates? Like a rank 2 covariant tensor:

$$
    g_{mn}^{\bm{e}'} = \pdd{x^i}{y^m}  \pdd{x^j}{y^n} g_{ij}^{\bm{e}}
$$

A metric enables identification identification of covariant and contravariant vectors: a contravariant vector $v$ *uniquely determines* a covariant vector $\alpha$ via the metric

$$
    \alpha(\cdot) := g (v, \cdot)
$$

Conversely each a covariant $\alpha$ *uniquely determines* a contravariant $v$.

As a result of this identification we can speak of the *covariant components* or *contravariant components* of a vector and one can pass between them using the *musical isomorphism*: Given a vector $v = v^i \bm{x_i}$ , we define its *flat* by 

$$
v^{\flat } := (g_{ij}v^{i})\mathbf {x}^{j}=v_{j}\mathbf{x} ^{j}
$$

where $g = g_{ij} x^i \otimes x^j$ is 2-covariant metric that is symmetric and nondegenerate.
This is referred to as "lowering an index".
In the same way, given a covector field $\alpha = \alpha_i \bm{u}^i$ , we define its *sharp* by

$$
\alpha^{\sharp }:=(g^{ij}\alpha_{i})\bm {u} _{j}=\alpha^{j}\bm{u}_{j}
$$

where $g^{ij}$ are the components of the inverse metric tensor (given by the entries of the inverse matrix to $g_{ij}$).
Taking the sharp of a covector field is referred to as "raising an index".

# Foonotes

<!-- [^1]: Assume a general, linear, second-order PDE in two variables $u(x,y)$

    $$
        Au_{xx}+2Bu_{xy}+Cu_{yy}+\cdots {\mbox{(lower order terms)}}=0,
    $$
    This form of the PDE resembles a conic section and naturally suggests a classification based on the value of the discriminant
    * $B^2 - A C < 0$: elliptic partial differential equation
    * $B^2 - A C = 0$: parabolic partial differential equation
    * $B^2 - A C > 0$: hyperbolic partial differential equation -->

[^2]: A good mnemonic is "low-co-row".
  
[^3]: Einstein summation convetion.

[^4]: A map from the vector space to the ground field that's linear in both of its arguments.

[^5]: Actually it's vector spaces; The *tensor product* $V \otimes W$ of two vector spaces $V$ and $W$ (over the same field) is itself a vector space, endowed with the operation of bilinear composition, denoted by $\otimes$, from ordered pairs in the Cartesian product $V \times W$ to $V \otimes W$ in a way that generalizes the outer product (quotienting).
