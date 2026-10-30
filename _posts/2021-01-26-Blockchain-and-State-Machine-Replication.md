---
layout: post
title: Blockchain and State Machine Replication
published: false
use_math: true
tags: [distributed-systems]
---



<p align="center">
  <img src="/images/3nodes.png" width="150"/>
</p>


# Footnotes

[^1]: [The Byzantine generals problem by Leslie Lamport](https://lamport.azurewebsites.net/pubs/byz.pdf)
[^3]: The only difference between agreement and broadcast is absence of a sender in agreement (i.e. honest nodes need only agree with each other and if their inputs agree then they must output those inputs).
[^4]: A graph $$S$$ covers $$G$$ if there is a mapping $$\phi: S \rightarrow G$$ that preserves neighbors.
[^5]: The state of every node and edge in the graph or subgraph throughout the course of the protocol.
[^6]: The behaviors of the nodes and edges in the subgraph.
[^7]: A primitive that takes a bit as input and returns a bit as output according to the protocol.
[^8]: A random oracle is a function that deterministically gives you a random answer i.e. "it knows a random answer for every question". One way to implement a random oracle is to use a hash function $$H: \{0,1\}^* \rightarrow [n]$$.