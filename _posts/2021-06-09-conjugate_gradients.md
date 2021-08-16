---
layout: post
author:
- Maksim Levental
excerpt_separator: <!--more-->
title: Conjugate Gradients
---

# Quadratic Forms

The gradient of quadratic form

$$f\left(\mathbf{x}\right)=\frac{1}{2}\mathbf{x}^{t}\mathbf{A}\mathbf{x}-\mathbf{b}^{t}\mathbf{x}+\mathbf{c}$$

<!--more-->

is

$$\begin{aligned}
\left.\nabla f\left(\mathbf{x}\right)\right|_{\mathbf{x}=\mathbf{x}_{0}} & =\left.\begin{bmatrix}\frac{\partial}{\partial x_{1}}f\\
\vdots\\
\frac{\partial}{\partial x_{n}}f
\end{bmatrix}\right|_{\mathbf{x}=\mathbf{x}_{0}}\\
 & \equiv\nabla f\left(\mathbf{x}_{0}\right)\\
 & =\frac{1}{2}\left(\mathbf{A}^{t}+\mathbf{A}\right)\mathbf{x}_{0}-\mathbf{b}\end{aligned}$$

If $$\mathbf{A}^{t}=\mathbf{A}$$ then

$$\begin{aligned}
\nabla f\left(\mathbf{x}_{0}\right) & =\mathbf{A}\mathbf{x}_{0}-\mathbf{b}\end{aligned}$$

hence minimizing $$f$$ is equivalent to solving
$$\mathbf{A}\mathbf{x}=\mathbf{b}$$ and vice-versa. If
$$\mathbf{A}^{t}=\mathbf{A}$$ and positive semi-definite and $$\mathbf{x}$$
is such that $$\mathbf{A}\mathbf{x}=\mathbf{b}$$ and let
$$\mathbf{y}=\mathbf{x}+\boldsymbol{\delta}$$. Then

$$\begin{aligned}
f\left(\mathbf{y}\right) & =\frac{1}{2}\left(\mathbf{x}+\boldsymbol{\delta}\right)^{t}\mathbf{A}\left(\mathbf{x}+\boldsymbol{\delta}\right)-\mathbf{b}^{t}\left(\mathbf{x}+\boldsymbol{\delta}\right)+\mathbf{c}\\
 & =\frac{1}{2}\mathbf{x}^{t}\mathbf{A}\mathbf{x}+\frac{1}{2}\boldsymbol{\delta}^{t}\mathbf{A}\mathbf{x}+\frac{1}{2}\boldsymbol{\mathbf{x}}^{t}\mathbf{A}\boldsymbol{\delta}+\frac{1}{2}\boldsymbol{\delta}^{t}\mathbf{A}\boldsymbol{\delta}-\mathbf{b}^{t}\mathbf{x}-\mathbf{b}^{t}\boldsymbol{\delta}+\mathbf{c}\\
 & =\frac{1}{2}\mathbf{x}^{t}\mathbf{A}\mathbf{x}+\boldsymbol{\delta}^{t}\mathbf{A}\mathbf{x}+\frac{1}{2}\boldsymbol{\delta}^{t}\mathbf{A}\boldsymbol{\delta}-\mathbf{b}^{t}\mathbf{x}-\mathbf{b}^{t}\boldsymbol{\delta}+\mathbf{c}\text{ by symmetry of }\mathbf{A}\\
 & =\frac{1}{2}\mathbf{x}^{t}\mathbf{A}\mathbf{x}+\boldsymbol{\delta}^{t}\mathbf{b}+\frac{1}{2}\boldsymbol{\delta}^{t}\mathbf{A}\boldsymbol{\delta}-\mathbf{b}^{t}\mathbf{x}-\mathbf{b}^{t}\boldsymbol{\delta}+\mathbf{c}\\
 & =\frac{1}{2}\mathbf{x}^{t}\mathbf{A}\mathbf{x}-\mathbf{b}^{t}\mathbf{x}+\mathbf{c}+\frac{1}{2}\boldsymbol{\delta}^{t}\mathbf{A}\boldsymbol{\delta}\\
 & =f\left(\mathbf{x}\right)+\frac{1}{2}\boldsymbol{\delta}^{t}\mathbf{A}\boldsymbol{\delta}\geq f\left(\mathbf{x}\right)\text{ by positive semi-definiteness of }\mathbf{A}\end{aligned}$$

Therefore for positive semi-definite and symmetric $$f$$ there exists a
unique minimum at $$\mathbf{x}=\mathbf{A}^{-1}\mathbf{b}$$.

# Gradient Descent

How to minimize $$f$$? Most naive strategy is to pick an arbitrary point
$$\mathbf{x}_{0}$$ and head down the gradient, i.e. head in the direction

$$\begin{aligned}
-\nabla f\left(\mathbf{x}_{0}\right) & =\mathbf{b}-\mathbf{A}\mathbf{x}_{0}\end{aligned}$$

Define $$\mathbf{r}_{0}\equiv-\nabla f\left(\mathbf{x}_{0}\right)$$. Then

$$\begin{aligned}
\mathbf{x}_{1} & =\mathbf{x}_{0}+\alpha_{0}\mathbf{r}_{0}\end{aligned}$$

But how to pick how far in the direction
$$\mathbf{r}_{0}\equiv-\nabla f\left(\mathbf{x}_{0}\right)$$ ? Do a “line
search” to minimize $$f$$ on the line
$$\mathbf{x}_{0}+\alpha_{0}\mathbf{r}_{0}$$, i.e. find where

$$\frac{d}{d\alpha}f\left(\mathbf{x}_{0}+\alpha_{0}\mathbf{r}_{0}\right)=0$$

By the chain rule

$$\begin{aligned}
\frac{d}{d\alpha}f\left(\mathbf{x}_{0}+\alpha_{0}\mathbf{r}_{0}\right) & =\left(\nabla f\left(\mathbf{x}_{0}\right)\right)^{t}\frac{d}{d\alpha}\left(\mathbf{x}_{0}+\alpha_{0}\mathbf{r}_{0}\right)\\
 & =\left(\nabla f\left(\mathbf{x}_{0}\right)\right)^{t}\mathbf{r}_{0}\end{aligned}$$

Therefore where $$\nabla f\left(\mathbf{x}_{0}\right)$$ and
$$\mathbf{r}_{0}$$ are orthogonal is minimum of $$f$$ on the line. We can
use this to determine $$\alpha_{0}$$

$$\begin{aligned}
-\left(\nabla f\left(\mathbf{x}_{0}\right)\right)^{t}\mathbf{r}_{0} & =0\\
\mathbf{r}_{1}^{t}\mathbf{r}_{0} & =0\\
\left(\mathbf{b}-\mathbf{A}\left(\mathbf{x}_{0}+\alpha_{0}\mathbf{r}_{0}\right)\right)^{t}\mathbf{r}_{0} & =0\\
\left(\mathbf{b}-\mathbf{A}\mathbf{x}_{0}\right)^{t}\mathbf{r}_{0}-\alpha_{0}\left(\mathbf{A}\mathbf{r}_{0}\right)^{t}\mathbf{r}_{0} & =0\Rightarrow\\
\alpha_{0}\left(\mathbf{A}\mathbf{r}_{0}\right)^{t}\mathbf{r}_{0} & =\left(\mathbf{b}-\mathbf{A}\mathbf{x}_{0}\right)^{t}\mathbf{r}_{0}\Rightarrow\\
\alpha_{0} & =\frac{\mathbf{r}_{0}^{t}\mathbf{r}_{0}}{\mathbf{r}_{0}^{t}\mathbf{A}\mathbf{r}_{0}}\end{aligned}$$

Therefore the gradient descent algorithm is a set of update rules

$$\begin{aligned}
\mathbf{r}_{i} & =\mathbf{b}-\mathbf{A}\mathbf{x}_{i}\\
\alpha_{i} & =\frac{\mathbf{r}_{i}^{t}\mathbf{r}_{i}}{\mathbf{r}_{i}^{t}\mathbf{A}\mathbf{r}_{i}}\\
\mathbf{x}_{i+1} & =\mathbf{x}_{i}+\alpha_{i}\mathbf{r}_{i}\end{aligned}$$

The complexity of the algorithm is dominated by matrix multiplications
$$\mathbf{A}\mathbf{x}_{i}$$ and $$\mathbf{A}\mathbf{r}_{i}$$ but we can
eliminate one: multiply the last update rule by $$-\mathbf{A}$$ and add
$$\mathbf{b}$$:

$$\begin{aligned}
\mathbf{b}-\mathbf{A}\mathbf{x}_{i+1} & =\mathbf{b}-\mathbf{A}\mathbf{x}_{i}-\alpha_{i}\mathbf{A}\mathbf{r}_{i}\\
\mathbf{r}_{i+1} & =\mathbf{r}_{i}-\alpha_{i}\mathbf{A}\mathbf{r}_{i}\end{aligned}$$

The disadvantage of using this recurrence relation is accumulation of
floating point roundoff error in computation of $$\mathbf{x}_{i}$$, not
corrected by this recurrence since it’s computed isolated from
$$\mathbf{x}_{i}$$. Solution is to periodically use the naive update rule
for $$\mathbf{r}_{i}$$.
So what’s the problem with this? Why can’t we just always use gradient
descent? Let

$$\begin{aligned}
f\left(\mathbf{x}\right) & =\frac{1}{2}\mathbf{x}^{t}\begin{pmatrix}2 & 1 & 0\\
1 & 2 & 0\\
0 & 0 & 2
\end{pmatrix}\mathbf{x}\\
 & =x_{1}^{2}+x_{1}x_{2}+x_{2}^{2}+x_{3}^{2}\end{aligned}$$

with $$\mathbf{x}_{0}=\left(1,2,3\right)$$. Minimizing direction
$$\mathbf{e}_{1}$$ we get to $$\mathbf{x}_{1}=\left(-1,2,3\right)$$ and
after minimizing in direction $$\mathbf{e}_{2}$$ we get to
$$\mathbf{x}_{2}=\left(-1,1/2,3\right)$$. But now the minimizing in the
$$\mathbf{e}_{1}$$ direction has been “messed up”, in that if the line
search along $$\mathbf{e}_{1}$$ is repeated it’s shifted to $$x_{1}=-1/4$$.
So the problem turns out to be that picking line search directions in
this manner selects directions that interfere with each other, undo
already effected minimizations. How can we pick directions that don’t
behave this way?

# Conjugate Directions

We want to choose directions $$\mathbf{v}$$ such that if we’ve just
performed a minimization along direction $$\mathbf{u}$$ it won’t be undone
I.e. we want $$\nabla f$$ to be perpendicular to $$\mathbf{u}$$ before and
after the minimization. This will be true if *the change in $$\nabla f$$
is perpendicular to* $$\mathbf{u}$$. Let $$\mathbf{x}_{i}$$ be the point
from which we set out in the direction $$\mathbf{u}$$. Then we want

$$\begin{aligned}
\mathbf{u}\cdot\delta\left(\nabla f\right) & =0\\
\mathbf{u}\cdot\nabla f\left(\mathbf{x}_{i+1}\right) & =0\text{ given that }\mathbf{u}\cdot\nabla f\left(\mathbf{x}_{i}\right)=0\\
\mathbf{u}\cdot\left(\nabla f\left(\mathbf{x}_{i+1}\right)-\nabla f\left(\mathbf{x}_{i}\right)\right) & =0\\
\mathbf{u}\cdot\left(\left(\mathbf{b}-\mathbf{A}\mathbf{x}_{i+1}\right)-\left(\mathbf{b}-\mathbf{A}\mathbf{x}_{i}\right)\right) & =0\\
\mathbf{u}\cdot\left(\mathbf{A}\mathbf{x}_{i}-\mathbf{A}\mathbf{x}_{i+1}\right) & =0\\
-\mathbf{u}\cdot\mathbf{A}\mathbf{v} & =0\end{aligned}$$

This is kind of not correct (since we don’t compute the gradients the
points we arrive at) but oh well it’s still true. We need a set of
directions $$\mathbf{d}_{i}$$ such that

$$\mathbf{d}_{i}\cdot\mathbf{A}\cdot\mathbf{d}_{j}=0\text{ for }i\ne j$$

Such a set of directions is called *conjugate*. So if we had in hand a
set of conjugate directions we could line search all each one in
sequence and minimize $$f$$ (in at most number of steps equal to the
number of conjugate directions). Very quickly a “technical” lemma

**Lemma**: If $$\mathbf{A}$$ is positive definite then a set of conjugate
vectors/directions
$$\left\{ \mathbf{d}_{0},\dots,\mathbf{d}_{n-1}\right\}$$ is linearly
independent and hence forms a basis for $$\mathbb{R}^{n}$$.

**Proof**: Let

$$\sum_{i=0}^{n-1}c_{i}\mathbf{d}_{i}=0$$

Then

$$\begin{aligned}
\mathbf{d}_{i}^{t}\mathbf{A}\sum_{i=0}^{n-1}c_{i}\mathbf{d}_{i} & =0\\
\sum_{i=0}^{n-1}c_{i}\mathbf{d}_{i}^{t}\mathbf{A}\mathbf{d}_{i} & =0\\
c_{i}\mathbf{d}_{i}^{t}\mathbf{A}\mathbf{d}_{i} & =0\end{aligned}$$

and hence $$c_{i}=0$$ since **$$\mathbf{A}$$** is positive definite.
Now we just need some conjugate directions. Gram-Schmidt to the rescue.
Start with a set of already linearly independent vectors/directions
$$\left\{ \mathbf{u}_{i}\right\}$$ (the standard basis vectors
$$\left\{ \mathbf{e}_{i}\right\}$$ will suffice) and use “conjugate”
Gram-Schmidt to “**A**-orthogonalize”

$$\mathbf{d}_{i}=\mathbf{u}_{i}-\sum_{k=0}^{i-1}\beta_{ik}\mathbf{d}_{k}$$

where $$\beta_{ik}$$ is the standard

$$\beta_{ik}=\frac{\mathbf{u}_{i}\mathbf{A}\mathbf{d}_{k}}{\mathbf{d}_{k}^{t}\mathbf{A}\mathbf{d}_{k}}$$

Here’s are the update rules if we have such a set
$$\left\{ \mathbf{d}_{0},\dots,\mathbf{d}_{n-1}\right\}$$

$$\begin{aligned}
\mathbf{r}_{i+1} & =\mathbf{r}_{i}-\alpha_{i}\mathbf{A}\mathbf{d}_{i}\\
\alpha_{i} & =\frac{\mathbf{d}_{i}^{t}\mathbf{r}_{i}}{\mathbf{d}_{i}^{t}\mathbf{A}\mathbf{d}_{i}}\\
\mathbf{x}_{i+1} & =\mathbf{x}_{i}+\alpha_{i}\mathbf{d}_{i}\end{aligned}$$

The computation of $$\mathbf{r}_{i}$$ is for the purposes of the line
search. So we’re set right? We can cook up some conjugate directions and
run the regular gradient descent right? Unfortunately this scheme has
the slight flaw that all conjugate vectors to have forever be kept in
memory and the quite serious flaw that all of the repetitive matrix
multiplications mean an $$O\left(n^{3}\right)$$ runtime.

# Conjugate Gradients

We just need to pick a more convenient set of vectors to
Gram-Schmidt-**A**-orthogonalize. I have an idea (not really me): let’s
use gradients/residuals! Why? Well firstly if we already have a set of
mutually **A**-orthogonal directions
$$\left\{ \mathbf{d}_{0},\dots,\mathbf{d}_{n-1}\right\}$$ then the
gradient computed on each line search will be orthogonal (straight-up
orthogonal) to preceeding line search directions. Here’s some proof: in
general (keep in mind we already have
$$\left\{ \mathbf{d}_{0},\dots,\mathbf{d}_{n-1}\right\}$$ in hand)

$$\begin{aligned}
\mathbf{x}_{1} & =\mathbf{x}_{0}+\alpha_{0}\mathbf{d}_{0}\\
\mathbf{x}_{2} & =\left(\mathbf{x}_{1}\right)+\alpha_{1}\mathbf{d}_{1}\\
 & =\left(\mathbf{x}_{0}+\alpha_{0}\mathbf{d}_{0}\right)+\alpha_{1}\mathbf{d}_{1}\\
 & \vdots\\
\mathbf{x}_{i+1} & =\mathbf{x}_{0}+\sum_{j=0}^{i}\alpha_{j}\mathbf{d}_{j}\\
 & \vdots\\
\mathbf{x}_{n-1} & =\mathbf{x}_{0}+\sum_{j=0}^{n-1}\alpha_{j}\mathbf{d}_{j}\end{aligned}$$

Note that $$\nabla f\left(\mathbf{x}_{n-1}\right)=0$$ since
$$\mathbf{x}_{n-1}$$ minimizes the quadratic form, so

$$\begin{aligned}
\mathbf{A}\mathbf{x}_{n-1}-\mathbf{b} & =\mathbf{A}\mathbf{x}_{0}-\mathbf{b}+\sum_{j=0}^{n-1}\alpha_{j}\mathbf{A}\mathbf{d}_{j}\\
\nabla f\left(\mathbf{x}_{n-1}\right) & =\nabla f\left(\mathbf{x}_{0}\right)+\sum_{j=0}^{n-1}\alpha_{j}\mathbf{A}\mathbf{d}_{j}\\
0 & =\nabla f\left(\mathbf{x}_{0}\right)+\sum_{j=0}^{n-1}\alpha_{j}\mathbf{A}\mathbf{d}_{j}\\
 & \Rightarrow\\
\nabla f\left(\mathbf{x}_{0}\right) & =-\sum_{j=1}^{n-1}\alpha_{j}\mathbf{A}\mathbf{d}_{j}\end{aligned}$$

and hence

$$\begin{aligned}
\mathbf{A}\mathbf{x}_{i+1}-\mathbf{b} & =\mathbf{A}\mathbf{x}_{0}-\mathbf{b}+\sum_{j=1}^{i}\alpha_{j}\mathbf{A}\mathbf{d}_{j}\\
\nabla f\left(\mathbf{x}_{i+1}\right) & =-\sum_{j=1}^{n-1}\alpha_{j}\mathbf{A}\mathbf{d}_{j}+\sum_{j=1}^{i}\alpha_{j}\mathbf{A}\mathbf{d}_{j}\\
 & =-\sum_{j=i+1}^{n-1}\alpha_{j}\mathbf{A}\mathbf{d}_{j}\end{aligned}$$

Finally

$$\begin{aligned}
\mathbf{d}_{k}^{t}\nabla f\left(\mathbf{x}_{i+1}\right) & =-\sum_{j=i+1}^{n-1}\alpha_{j}\mathbf{d}_{k}\mathbf{A}\mathbf{d}_{j}\\
 & =0\text{ by $\textbf{A}$-orthogonality for }k<i\end{aligned}$$

Intuitively this makes sense because on every line search we’re choosing
$$\alpha_{i}$$ so that it’s orthogonal to the search direction (though of
course this in and of itself isn’t a guarantee that orthogonality will
be preserved - cue the above proof). Succinctly with
$$\mathcal{D}_{i-1}=\text{span}\left(\left\{ \mathbf{d}_{0},\dots,\mathbf{d}_{i-1}\right\} \right)$$
it’s the case that the hyperplane/linear-variety
$$\mathbf{x}_{0}+\mathcal{D}_{i}$$ is tangent to the level surface of
$$f\left(\mathbf{x}_{i}\right)$$, an ellipsoid, and hence the gradient
$$\nabla f\left(\mathbf{x}_{i}\right)\cdot\mathcal{D}_{i}=0$$. Furthermore
(remember $$\mathbf{r}_{i}\equiv\nabla f\left(\mathbf{x}_{i}\right)$$)
using the direction update rule from conjugate directions with
$$\mathbf{u}_{i}=\mathbf{r}_{i}$$

$$\begin{aligned}
\mathbf{d}_{i} & =\mathbf{r}_{i}-\sum_{k=0}^{i-1}\beta_{ik}\mathbf{d}_{k}\\
 & \Rightarrow\\
\mathbf{d}_{i}^{t}\mathbf{r}_{j} & =\mathbf{r}_{i}^{t}\mathbf{r}_{j}-\sum_{k=0}^{i-1}\beta_{ik}\mathbf{d}_{k}^{t}\mathbf{r}_{j}\\
 & =\mathbf{r}_{i}^{t}\mathbf{r}_{j}\end{aligned}$$

It gets even better. If we use gradients to **construct** the search
directions then (remember
$$\mathbf{r}_{i}\equiv\nabla f\left(\mathbf{x}_{i}\right)$$)

$$\text{span}\left(\left\{ \mathbf{r}_{0},\dots,\mathbf{r}_{i-1}\right\} \right)=\text{span}\left(\left\{ \mathbf{d}_{0},\dots,\mathbf{d}_{i-1}\right\} \right)$$

remember that
$$\mathbf{r}_{i+1}=\mathbf{r}_{i}-\alpha_{i}\mathbf{A}\mathbf{r}_{i}$$ so
actually

$$\begin{aligned}
\text{span}\left(\left\{ \mathbf{r}_{0},\dots,\mathbf{r}_{i-1}\right\} \right) & =\text{span}\left(\left\{ \mathbf{r}_{0},\mathbf{A}\mathbf{r}_{0},\mathbf{A}^{2}\mathbf{r}_{0},\dots,\mathbf{A}^{-1}\mathbf{r}_{0}\right\} \right)\end{aligned}$$

This is a *Krylov* subspace, a subspace created by repeatedly applying a
matrix to a vector. The use is that since
$$\mathbf{A}\mathcal{D}_{i-1}\subset\mathcal{D}_{i}$$ and that
$$\mathbf{r}_{i}\cdot\mathcal{D}_{i}=-\nabla f\left(\mathbf{x}_{i}\right)\cdot\mathcal{D}_{i}=0$$
means that $$\mathbf{r}_{i}\cdot\mathbf{A}\mathcal{D}_{i-1}=0$$! That
means Gram-Schmidt-**A**-orthogonalization reduces to just one term
(just the direction purely in $$\mathcal{D}_{i}$$) ! From Gram-Schmidt

$$\mathbf{d}_{i}=\mathbf{u}_{i}-\sum_{k=0}^{i-1}\beta_{ik}\mathbf{d}_{k}$$

but from conjugate directions and the result above
$$\mathbf{d}_{i}^{t}\mathbf{r}_{j}=\mathbf{r}_{i}^{t}\mathbf{r}_{j}$$ and
that $$\mathbf{r}_{i}^{t}\mathbf{r}_{j}=0$$ if $$i\neq j$$

$$\begin{aligned}
\mathbf{r}_{i+1} & =\mathbf{r}_{i}-\alpha_{i}\mathbf{A}\mathbf{d}_{i}\\
 & \Rightarrow\\
\mathbf{r}_{j}^{t}\mathbf{r}_{i+1} & =\mathbf{r}_{j}^{t}\mathbf{r}_{i}-\alpha_{i}\mathbf{r}_{j}^{t}\mathbf{A}\mathbf{d}_{i}\\
 & \Rightarrow\\
\alpha_{i}\mathbf{r}_{j}^{t}\mathbf{A}\mathbf{d}_{i} & =\mathbf{r}_{j}^{t}\mathbf{r}_{i}-\mathbf{r}_{j}^{t}\mathbf{r}_{i+1}\\
\mathbf{r}_{j}^{t}\mathbf{A}\mathbf{d}_{i} & =\begin{cases}
\frac{1}{\alpha_{i}}\mathbf{r}_{i}^{t}\mathbf{r}_{i} & \text{if }i=j\\
-\frac{1}{\alpha_{i-1}} & \mathbf{r}_{i}^{t}\mathbf{r}_{i}\text{if }i=j+1
\end{cases}\\
 & \Rightarrow\\
\beta_{ij} & =\begin{cases}
\frac{1}{\alpha_{i}}\frac{\mathbf{r}_{i}^{t}\mathbf{r}_{i}}{\mathbf{d}_{i-1}^{t}\mathbf{A}\mathbf{d}_{i-1}} & \text{if }i=j+1\\
0 & \text{if }i>j+1
\end{cases}\end{aligned}$$

Simplifying further since only $$\beta_{i,i-1}\equiv\beta_{i}$$ are
non-zero

$$\begin{aligned}
\beta_{i} & =\frac{1}{\alpha_{i}}\frac{\mathbf{r}_{i}^{t}\mathbf{r}_{i}}{\mathbf{d}_{i-1}^{t}\mathbf{A}\mathbf{d}_{i-1}}\\
 & =\frac{\mathbf{r}_{i}^{t}\mathbf{r}_{i}}{\mathbf{d}_{i-1}^{t}\mathbf{r}_{i-1}}\end{aligned}$$

Finally the entire set of update rules

$$\begin{aligned}
\mathbf{d}_{0} & =\mathbf{r}_{0}\\
\alpha_{i} & =\frac{\mathbf{r}_{i}^{t}\mathbf{r}_{i}}{\mathbf{d}_{i}^{t}\mathbf{A}\mathbf{d}_{i}}\\
\mathbf{x}_{i+1} & =\mathbf{x}_{i}+\alpha_{i}\mathbf{d}_{i}\\
\mathbf{r}_{i+1} & =\mathbf{r}_{i}-\alpha_{i}\mathbf{A}\mathbf{d}_{i}\\
\beta_{i+1} & =\frac{\mathbf{r}_{i+1}^{t}\mathbf{r}_{i+1}}{\mathbf{d}_{i}^{t}\mathbf{r}_{i}}\\
\mathbf{d}_{i+1} & =\mathbf{r}_{i}-\beta_{i+1}\mathbf{d}_{i}\end{aligned}$$
