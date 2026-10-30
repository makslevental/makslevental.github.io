---
layout: post
title: Abel-Rufini theorem
published: true
tags: [math]
---

This post follows [this video](https://www.youtube.com/watch?v=zeRXVL6qPk4) and explicates Arnold's topological proof of Abel-Ruffini.

Abel-Ruffini states that there is no general *algebraic solution* to polynomial equations of degree five

$$
	ax^5 + bx^4 + cx^3 + dx^2 +ex +f  = 0
$$

or higher.


An algebraic solution to a polynomial equation is a "formula" for the *roots* of the polynomial consisting of only sums, differences, products, quotients, powers, and arbitrary roots of the complex coefficients polynomials. 

Juxtapose this with second order polynomial equations

$$
	a x^2 + bx + c = 0
$$

where we have the algebraic solution for the roots (otherwise known as the *quadratic formula*)

$$
	x = \frac{-b \pm \sqrt{b^2 -4ac}}{2a}
$$

# Idea

The idea is to continuously perturb each of the coefficients of the polynomial along a loop (change each of them from their initial value such that they traverse a path that returns them to their initial value at the end of the path) and study what happens to the roots.

<iframe style="display:block;margin:auto" width="560" height="315" src="https://www.youtube.com/embed/zeRXVL6qPk4?start=138" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

Note that once all coefficients have returned to their original values the entire set of roots also returns to itself, **but** each root does not necessarily returns to its original value.
In general you get a *permutation* of the set of roots and so in this way we get a mapping (relationship) between loop perturbations of the coefficients and permutations of the roots.

Also note that we can produce coefficient loops that map to any permutation of the roots by permutating the roots and "watching" the coefficients.

Hence, the way to prove Abel-Ruffini is to show that any expression involving the coefficients (formula for the roots) returns to itself after the coefficients traverse their loops but the roots do not (and therefore the expression cannot capture  all of the roots). 
For example, an immediate corollary of the construction of the mapping between loops of coefficients and roots is the fact that a general solution involving only $-, +, \times, \div$ is not possible; $-, +, \times, \div$ are all single-valued (and therefore no composition thereof could produce multiple roots).

<iframe style="display:block; margin:auto" width="560" height="315" src="https://www.youtube.com/embed/zeRXVL6qPk4?start=320" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

# Roots

While purely arithmetic functions of the coefficients are single-valued and immediately eliminated as possible tools to produce the roots, we *can* use $n$th order roots (but ultimately that won't be sufficient either). 
Take for example 

$$
	\sqrt[3]{\frac{a+b}{c}+f+1} 
$$

While the argument $z := \frac{a+b}{c}+f+1$ will return to its original value as we perturb $a,b,c,f$ around loops, the whole expression will not. 
This is due to simply how complex numbers work; if $z = re^{i \theta}$ then

$$
\begin{align}
	\sqrt[n]{z} &= \sqrt[n]{r} e^{i \theta /n} \\
	&= \sqrt[n]{r} e^{i \theta /n + 2\pi/n} \\
	&= \sqrt[n]{r} e^{i \theta /n + 4\pi/n} \\
	& \qquad\vdots\\
	&= \sqrt[n]{r} e^{i \theta /n + 2k\pi/n} 
\end{align}
$$

and so while $z$ will return to itself, the $n$th root is dependent on $\Delta \theta = 2\pi k$, i.e. how many ($k$) complete loops (in fact around the origin) $z$ traverses.

# Commutators

Despite this ambiguity we can still build loops for the coefficients to traverse that *do* return the $n$th root to itself; since the $n$th root only depends on $\Delta \theta$ we can simply traverse a set of loops backwards and forwards

<iframe style="display:block; margin:auto" width="560" height="315" src="https://www.youtube.com/embed/zeRXVL6qPk4?start=544" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

using the *commutator* 

$$
	[z_1(t), z_2(t)] := z_1(t)z_2(t)z_1(-t)z_2(-t)
$$

of the loops (where $z_1(-t)$ indicates we traverse loop $z_1$ backwards). 

For such a combination of loops $\Delta \theta = 0$ and so the values produced by the $n$th root return to themselves.
This immediately proves that any expression involving only one root cannot be a general expression for the same reason as for arithmetic functions of the coefficients - because we can construct loops such that values of a single $n$th root return to themselves but the solutions of the polynomial equation do not:

<iframe style="display:block; margin:auto" width="560" height="315" src="https://www.youtube.com/embed/zeRXVL6qPk4?start=600" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

# Nested roots

The way forward to the ultimate proof is in the answer on how to handle functions of the coefficients involving nested roots such as

$$
	\sqrt[3]{c + \sqrt{b+d}}  
$$

The answer is to construct two commutators for which $\sqrt{b+d}$ returns to itself

$$
\begin{align}
	C_1(t) &:= [z_1(t), z_2(t)] \\ 
	C_2(t) &:= [z_3(t), z_4(t)] \\
\end{align}
$$

Since $c$ does not involve any roots it also returns to its original value when traversing the commutator loops $C_1, C_2$.
Therefore we have two loops for which the argument $z := c + \sqrt{b+d}$ of $\sqrt[3]{z}$ returns to its original value and hence the commutator

$$
	C(t) := [C_1(t), C_2(t)]
$$

must return composite expression to its original value.
This naturally extends to deeper nesting by building commutators of commutators of commutators... i.e. a tower of commutators.

So this resolves how to build loops such that functions of the coefficients involving nested roots (to any depth) return to their original values. 
But it is possible that after traversing all of these loops the solutions to the polynomial equation do in fact return to themselves. 
It remains to show that we can infact construct towers of commutators such that the solutions to the polynomial equation do not in fact return to themselves while the values of the purported formulaic expression do.

# Permutations

Note that we do not actually need the entire path trajectory of the solutions to the polynomial equation; we only need to know how the solutions are permuted.
Take for example a loop path that permutes $x_3$ and $x_4$ 

$$
	P_1 := (1 2 4 3 5)
$$

and another loop path that permutes $x_3$ and $x_1$

$$
	P_2 := (3 2 1 4 5)
$$

The commutator of these two permutations is 

$$
	P := [P_1, P_2] = P_1 P_2 P_1^{-1} P_2^{-1} = (4 2 1 3 5)
$$

This means we only need to inspect permutations of $n$ objects. 
For example in the case of $n=2$ (quadratic equations) we only have two possible permutations of the roots

$$
\begin{align}
	P_1 &:= (12) = I \\
	P_2 &:= (21)
\end{align}
$$

and you can check that $P := [P_1, P_2] = (12) = I$ the identity permutation and therefore any commutator of loops of the coefficients of a quadratic equation does in fact return the solutions of that equation to themselves (and hence a quadratic formula does in fact express the solutions accurately).

# $S_5$

There are 120 unique permutations on 5 elements.
Therefore (taking two such permutations) there are $120 \times 120 = 14,400$ different commutators.
But note that these 14,400 different commutators cannot all be unique since a commutator of permutations is itself a permutation.
In fact, these 14,400 different commutators turn out to be only 60 unique permutations (this can be computed exactly by composing the permutations and counting the number of unique results)

<iframe style="display:block; margin:auto" width="560" height="315" src="https://www.youtube.com/embed/zeRXVL6qPk4?start=1202" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

This shows that expressions with a single root cannot accurately characterize the solutions to 5th degree polynomial (because we can construct loops of the coefficients that do return the expression to itself but do not return the roots to themselves). 
What about expressions with a nested root?
For this we need to check the number unique permutations that comprise the set of all commutators of commutators (of which there are $60 \times 60$)

<iframe style="display:block; margin:auto" width="560" height="315" src="https://www.youtube.com/embed/zeRXVL6qPk4?start=1318" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

Here we find that this set of permutations is the same set of 60 permutations that we found when constructing commutators of loops. 

This is the final component of the proof; no matter how many levels of commutator composition we produce there will always be loops of the coefficients that return any expression with nested roots (to any depth) that do not return the solutions to themselves (and therefore contradict any claim that that expression accurately finds all of the solutions of the polynomial equation).
