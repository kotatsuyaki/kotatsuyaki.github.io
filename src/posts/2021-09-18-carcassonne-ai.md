---
title: "Bringing Intelligence to Carcassonne with MCTS"
description: "My journey towards AlphaZero-style bots for a board game (Part I)"
date: 2021-09-18
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

![Game interface written with Flutter, a by-product of this project](/images/Screenshot_20210918_215801.png)

Last year on an undergraduate course about machine learning, where everybody's got to invent their
own topics for the final project, I along with my teammate chose to pick up the chance to try if
we were able to replicate the well-known reinforcement learning algorithm AlphaZero for
[Carcassonne](<https://en.wikipedia.org/wiki/Carcassonne_(board_game)>), the board game we loved[^1].
Later on, I opted to keep on going for new possibilities beyond the conventional configuration of
AlphaZero, making it the topic of my independent study.
This post summarizes what I've done so far along the journey of exploration, as well as ideas that
I have yet to actually try.

<!-- more -->

# Implementing the game logic

The game logic of Carcassonne is full of enumerating, filtering, and flood filling operations.
Since the search algorithm hugely benefit from fast simulations (we'll see that later), it was
written in Rust instead of languages like python.

The very first implementation of the game logic, included as part of our final project last year,
has pretty much all the game details hardcoded by hand: the edge features of the tiles, the counts,
the adjacent castle features of the fields, _everything_.
We lived with the hardcoded approach since we were running out of time, but recently it has
undergone a complete rewrite using a better approach - the tile configurations are now generated
from a much more human-readable CSV file using a Python script[^2].

![The CSV file used to generate boilerplate code](/images/Screenshot_20210918_225354.png)

# Implementing the UI

(There's a [debug version publicly available](http://akitaki.ml:5000/) - the url is subject to change)

For debugging purposes, I've been wanting a custom UI for Carcassonne for a long time,
but it wasn't until recently that I actually put my hands to craft one.
Existing projects like [JCloisterZone](https://github.com/farin/JCloisterZone) are great for
gameplays, but what I needed was an even simpler UI that I can hook up to any backend providing a
small set of remote call api.

The UI was written in Dart using Flutter, with a fairly simple remote procedure calling interface as
the the means of communication between the server and the clients:

```proto
service GameService {
    rpc createRoom(CreateRoomRequest) returns (CreateRoomResponse);
    rpc joinRoom(JoinRoomRequest) returns (JoinRoomResponse);
    rpc gameState(GameStateRequest) returns (GameStateResponse);
    rpc doAction(DoActionRequest) returns (Empty);
}
```

The basic idea is to have the clients perform [long polling](https://en.wikipedia.org/wiki/Push_technology#Long_polling)
with the game server. The server holds the incoming requests and responds only if:

1. The client's previous state has an serial number older than the latest one.
2. The server performed a state update.

To keep it as simple as possible, the states are always synchronized fully without any partial
updates.

# Applying MCTS to Carcassonne

While being the core algorithm of AlphaZero, [MCTS](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search#Principle_of_operation)
is actually strikingly simple in its principle.
We build a tree that has only a root node at the beginning.
For an arbitrary number of iterations,

1. Walk downwards until a leaf node $L$ is hit. At every level, a strategy that balances between known
   good moves and unexplored moves is employed to choose our destination.
2. Create new leaf nodes for the leaf node we hit, if any.
3. Simulate a completely random game from $L$, generating an outcome between 0 and 1, and record this
   information back to every ancestor of $L$.

There are some problems though, when it comes to applying this general algorithm to Carcassonne.

## The stochasticity problem

The outline we have just given assumes that between two player actions, there are no environment
actions (i.e. drawing cards) at all. To solve this problem, the search tree is constructed with
two kinds of layers of nodes:

- **Type-D** nodes (D for **deterministic**). The game states associated with them are **after** drawing cards.
- **Type-U** nodes (U for **undeterministic**). The game states associated with them are **before** drawing cards.

![The search tree with two types of nodes](/images/dutree.svg)

As with normal MCTS search trees, we store the number of visits and cumulative scores in the nodes. 
Upon navigating to a node, we perform selection using different strategies based on the type of the node.
For type-D nodes, we use the UCT formula[^uct] to select an optimal child node, and for type-U nodes,
we do a sampling on the remaining cards instead.

[^uct]: $\frac{w_i}{n_i} + c\sqrt{\frac{\ln N_i}{n_i}}$

Note that we don't store the cumulative scores on the type-D nodes.
The reason for this is that in the UCT formula, when evaluating the score of a child node
(which must be a **type-U** node), we only need the child's cumulative score $w$.

I swear that I came up with this idea on my own, but this turned out to be already written in an
[existing paper](https://arxiv.org/abs/2009.12974) about MCTS and Carcassonne that I overlooked.

## The memory usage problem

Unlike Simpler games like gomoku, go, or chess, Carcassonne is much more complicated and requires
a large amount of memory to hold the game states associated with the tree nodes,
The situation is even worse on cloud servers since the AWS free tier instances have only 1 gigabyte of memory -
all it takes to trigger oom-killer on these instances is a thousand-iteration MCTS search.

This is actually not always the case though - after applying lazy-initialization to the node states
(compute and store a new state only when it's selected / sampled), we observed almost 90% drop in
memory usage.

```rust
enum Data {
    Determ {
        state: OnceCell<Box<Board>>,
        last_draw: TileKind,
        visits: usize,
        weight: usize, // for sampling draws
    },
    Undeterm {
        state: OnceCell<Box<Board>>,
        last_action: Action,
        visits: usize,
        value: f32, // for selecting actions
    },
}
```

Above shows the type definition for node data.  It fits nicely into a sweet sum type provided by the language.
Notice how the type of `state` is constructed:

- A [once-cell](https://lib.rs/crates/once_cell) is used for lazy initialization.  Its size in memory
  depends on the size of the type that it wraps.
- A `Box` is used to reduce the uninitialized size of the cell.  Had it not been for this pointer
  indirection, the once-cell would have been as large as the `Board` type, which completely invalidates
  our goal of reducing memory consumption in the first place.

![Simple indirection may save the day](/images/indir.svg)

Apart from these small adjustments, the implementation in Rust is pretty much a literal translation
from the description, which is
[under 400 lines of code](https://gitlab.com/Akitaki/carcassonne-rust/-/blob/bdffaaa54db21a8b97037598cdcc44fbcb370179/carcassonne-mcts/src/lib.rs#L34)
in the `impl` block.
Performance-wise, it's almost on par with average human players at around 4000 iterations, which
is quite remarkable considering the simplicity of the algorithm.

The code of the project resides in these repositories.

- [`carcassonne-ui`](https://gitlab.com/kotatsuyaki/carcassonne-ui) (the flutter app)
- [`carcassonne-rust`](https://gitlab.com/kotatsuyaki/carcassonne-rust) (the backend part)

# References

- [*Playing Carcassonne with Monte Carlo Tree Search*](https://arxiv.org/abs/2009.12974) paper
- [Monte Carlo tree search](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search) on wikipedia

---

[^1]: Actually it's the game that **I** love. My poor little teammate was forced to keep my company
      on the topic.

[^2]: Using an external script to generate Rust code is still not idiomatic, I admit. A
      [proc macro](https://doc.rust-lang.org/reference/procedural-macros.html) seems like a nice fit
      to this problem. The biggest obstacle right now is that proc macros are way harder to debug
      than my lovely script, so I'm sticking to Python at the moment.
