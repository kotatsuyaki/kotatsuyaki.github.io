---
title: "Bringing Intelligence to Carcassonne with a Graph Neural Network"
description: "My journey towards AlphaZero-style bots for a board game (Part II)"
date: 2021-09-19
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

*2021/10/04 update: Rust-C++ interop with the cxx crate*

In [my previous post](/carcassonne-ai), I shared about how I learned and attempted to use simple
MCTS algorithm to solve the board game Carcassonne
This post is a follow-up of that, where I'd like to talk about how I applied the AlphaZero (and beyond!)
model on the same game.

<!-- more -->

Parts of this article were originally collected from my private notes and commit logs, so expect it
to be a little bit long and inconsistent.

# From MCTS to AlphaZero

From an algorithmic point of view, the difference between simple MCTS and AlphaZero is almost negligible.

1. There's no more random simulations.
   Instead of using simulations to estimate the outcome in `[0, 1]`,
   a _value network_[^1] is used to do the same job.
2. The selection formulae are different. AlphaZero uses a variant called PUCT, which looks like this.

   $$Q(s, a) + c_{\text{puct}}P(s, s') \frac{\sum_x N(s, x)}{1 + N(s, s')}$$

   The first term remains the same as UCT, which is the average value so far for the node.
   The second term incorporates $P$, which is the policy prior obtained by feeding the game state $s$
   into another network called the _policy network_[^1].

The largest challenge involved in implementing AlphaZero though, is that the number of inferences
(forward passes on the neural networks) required is fairly large.
Even for the simplest games like five-in-a-row,
over ten thousand game matches is required to train the model to an acceptable level of strength,
which translates to millions times of forward passes.
The approach I adopted was to have a large number of selfplay threads running and sending the inference
requests to a single "inference service" thread for the neural network.
The inference service thread waits for a fixed number of requests to fill a batch before running
an inference - this is critical to avoid I/O overhead introduced by transferring data between
the CPU and GPU.

![My poor man's single-machine AlphaZero architecture](/images/batch.svg)

# From CNN to GNN

## Why GNN?

The previous section pretty much sums up what I did for the final project last year - it successfully
achieved slightly better performance compared to simple MCTS algorithm, but with some caveats.

1. 3-dimensional tensors are actually not the most suitable format to represent the game states of Carcassonne.
   Sure, we one-hot encoded the tile kinds, the rotations, along with the occupation information
   to it, but there's no guarantee that the CNN will be able to easily learn useful information
   out of the tensors.

2. **The input size is fixed**, which implies that the board size is also fixed.
   This is an inherent property of of the network structure, since we have a fixed number of output
   units for policy prediction.

   Since in a regular gameplay of Carcassonne there's 72 tiles to be placed, the board may get as
   large as 72 tiles in its radius, which makes the input dimensions $145\times 145\times M$ where $M$ is the
   number of features per tile (which itself can grow over a hundred).

At the time when I did the final project last year, I opted to limiting the board (table) size
under a certain number.
It worked, but it was like a crippled bot that couldn't play normal games, and I wasn't satisfied with it.

There's [a fairly recent paper](https://arxiv.org/abs/2107.08387) about using graph neural networks
(i.e. networks with graph data structure as their inputs) to alleviate the scalability problem of AlphaZero.
In their work, they replaced CNN's with GNN's (graph neural networks), which addresses the fixed-sized input problem.
However, they did **not** try to solve the input shape issue, since they're using graphs with the
same structure as inputs, regardless of the game state.

![Grid-like graph structure for othello used in their work.](/images/othello-graph.png)

This looked wasteful to me - graphs are one of the most versatile representation of data,
and can potentially carry a lot more information beyond the node features, ecspectially for Carcassonne.
Human players of the game usually rely on tracing the **conneceted area** of features like castles
and roads, counting **the number of castles connected to a field** and so on, which can be neatly
modeled in a graph by adding different kinds of interconnections between the nodes.

## Background: Graph neural networks

Graph neural networks are, as suggested by the name, a class of deep learning models with graphs
as the input data.
The most popular GNN models are all based on the **message-passing** framework, meaning that for
each layer of the network with input $x^{(k-1)}$, we have the following formula to compute the next layer's input.

$$x_i^{(k)} = \sigma^{(k)} \left(x_i^{(k-1)}, \square_{j\in N(i)}\phi^{(k)}\left(x_i^{(k-1)}, x_j^{(k-1)}\right)\right)$$

The math may seem scarry, but it's nothing more than

1. Computing embeddings for each node within the neighborhood.
   The $\phi$ there computes a single embedding from two connected nodes.
2. **Aggregating** the computed node embeddings into a single vector.
   The $\square$ there can be mean, sum, or anything else.
3. Applying a nonlinear function $\sigma$ to enhance its expressiveness.

The conventional way to create graph neural networks is to use the [PyTorch Geometric](https://github.com/pyg-team/pytorch_geometric).
Most well-known types of layers are included in the `torch_geometric.nn` module, so it's usually
not needed to reinvent the wheel from scratch.
Training can be done as usual with back propagation using `torch.optim`, be it node-level prediction or graph-level prediction.

For an in-depth walkthrough of graph neural networks I highly recommend
[CS224W lectures on stanfordonline](https://www.youtube.com/playlist?list=PLoROMvodv4rPLKxIpqhjhPgdQy7imNkDn)
by Jure Leskovec, which covers almost all aspects of graph machine learning topics.

## Designing a GNN for Carcassonne

### The input graph

For the sake of simplicity, I modeled the game states as **undirected**, **homogeneous** graph and
**without edge features**.
Each node represents either a tile, a feature (e.g. a single patch of a long road), or an connected
area of features (e.g. a castle spanning across multiple tiles), each with additional data like occupation
status stored as node features.

The conversion from game states to graphs is designed solely based on (my) human knowledge about the game.
Important edges such as

- those between candidate actions and tiles that are already placed
- those between areas of the same color,
- those between adjacent castles and fields, etc.

are added to the graphs.
I'm pretty bad at making diagrams, but this is my attempt - the actual graphs are much more complicated
(and denser) than this one to model the complex dynamics of the game, but you get the idea:

![](/images/ccs.svg)

### The model

![My current network diagram. Selfloops represent repetitions.](/images/network.svg)

The overall network architecture is more or less the same as the one used in the _Train on Small,
Play the Large_ paper, except for some minor adjustments on the choice of layer types and pooling operations (mean v.s. sum).
As of the time of writing, what I have now are

- Several dense layers for preprocessing the raw node features
- Three GATv2 attention layers from [_How Attentive are Graph Attention Networks?_](https://arxiv.org/abs/2105.14491).
- A global _add_ pool with several dense layers (and a sigmoid at the end) as the value head.

  This choice is based on [the rationale](https://arxiv.org/abs/1810.00826) that summation is more
  powerful than mean or max operations when classifying graphs, which is closely related to our value
  prediction head (graph-level regression).

  ![Summation is more expressive when classifying graphs.](/images/x3.png)

### Experimental result so far

Preliminary experimental results last week suggested that this approach works for basic gameplay
at least.
The GNN-based model beaten random baseline agent within the first 6 hours of training, and
is almost on par with my previous simple MCTS agent after two days of training.
I'm still running it to see if it's actually capable of improving beyond that level of strength.

# Closing thoughts

A friend of mine once told me that he's disappointed after learning all the deep learning stuff,
because what we have are just "non-linear function twisting machines".

A lot of techniques in programming are actually all about pre-computing and storing answers.
When the number of possible inputs is small, we build a lookup table.
When the number of possible inputs is too large, we build a cache.
When the number of possible inputs goes crazy, we build fancy function approximators (refered to as
neural networks) to get inaccurate but still useful answers.

We have what we have, and they're at least effective for the goals we care about.

---

# Appendix for rants: Deep learning and Rust

The AlphaZero algorithm itself seemed good until I started coding. **Avoid Rust and stick to Python
at all costs** if you want to do DL stuff without shooting yourself in the foot.

Most, if not all, of the deep machine learning toolchains are all tightly tied to the Python language,
while I've written the game engine in Rust in the first place.
Of course I could've re-written it in Python, but that would be whole orders of magnitude slower than
the highly optimized Rust implementation.
There's also [the infamous global lock](https://wiki.python.org/moin/GlobalInterpreterLock) in CPython,
effectively preventing multiple threads from running at the same time.

So far I've found several approaches to accessing popular DL frameworks (namely tensorflow and pytorch)
from a Rust program - each with their own strengths and weaknesses.
Below is a list of what I've tried within the last year or so, ordered by time:

1. The [TensorFlow bindings for Rust](https://github.com/tensorflow/rust).

   This was the route I went with the first time, but the experience left a bad taste in my mouth.
   Although it's advertised as an "idiomatic wrapper" around the C API or TensorFlow (which is still
   experimental anyways), it's awfully low level for regular tasks, and provides no obvious public
   API train existing model exported from Python code.
   I ended up with a workaround where I define the training routines (model training and saving)
   as decorated `@tf.function`'s and manually specifying the input type signatures.

   Aside from API usability issues, the library is a good fit for my use case.

2. The [PyTorch bindings for Rust](https://github.com/LaurentMazare/tch-rs).

   This one is subjectively much more polished than that of TensorFlow.
   Their repository includes several examples demonstrating how to load and train TorchScript (jit)
   models exported from Python.

   It _almost_ worked for training, except for that it lacks an API for saving optimizers.
   For a while, I forked the library and contributed some small patches upstream, but since I wasn't
   expecting to maintain a DL library merely just to use it, I steered away from this quickly.

3. Using PyTorch from Python, with gRPC for the inferencing service.

   This also _almost_ worked for the purpose.
   There's only one problem left: _it's slow_.
   My (inaccurate) basic profiling suggests that the time spent on serializing + sending the tensors
   over the network is longer than the time spent on the model's `forward()` call.

4. Embed a Python interpreter in the Rust main program using [PyO3](https://pyo3.rs).

   This neat library enables us to translate the following code:

   ```python
   from model import Model
   model = Model()
   model = model.to('cuda')
   ```

   into totally safe Rust code:

   ```rust
   let model = Python::with_gil(|py| {
       let model = PyModule::import(py, "model")?.getattr("Model")?;

       let model = model.call0()?;
       let model = model.getattr("to")?.call1(("cuda",))?;
       Ok(model.to_object(py))
   })?;
   ```

   There's also a great accompanying library called [numpy](https://lib.rs/crates/numpy) for Rust
   that allows conversions between numpy arrays on the Python side and `ndarray` types on the Rust
   side.
   For example, to send a node feature array from Rust to Python, one can do:

   ```rust
   let to_torch = torch.getattr("from_numpy")?;
   let nodes = graph.nodes.to_pyarray(py);
   ```

   There are still drawbacks of using an embedded Python interpreter though:
   **It's still slower than expected**, and it's not saturating all the available GPU resources
   for inference.
   Upon closer inspection and profiling, I suspect that this is once again caused by the GIL.
   After sending a job with `forward()` there's virtually no way other threads can concurrently
   run `forward()` again on different threads, which hinders parallelism a lot, since the inference
   is done in a send-and-wait manner without any chance of overlapping multiple inferences,
   even though I _know_ it's completely safe to do so without potential risks of race conditions.

5. Call C++ code from Rust using the [cxx crate](https://cxx.rs).

   My current approach.
   With this manual and verbose C++ solution, the GPU utilization stays >95% most of the time.

   This library shifts the responsibility of doing safety checks from the _users_ to the _compiler_,
   by making sure that the function signatures on both sides agree with each other.

   My setup is to have:

   - A standalone CMake project doing all the libtorch-related stuff. The part is compiled as a
     static library for the main program(s) written in Rust to be linked with.
   - A bridging interface between Rust and C++, compiled from the cargo side. To make the interface
     simple and flexible, raw `*mut T` pointers are passed.

     ```rust
     unsafe fn inference(
         self: &Gnn,
         x_data: *mut f32,
         x_shape: *mut i64,
         x_shape_len: usize,
         edge_index_data: *mut i64,
         edge_index_shape: *mut i64,
         edge_index_shape_len: usize,
         batch_data: *mut i64,
         batch_shape: *mut i64,
         batch_shape_len: usize,
     ) -> UniquePtr<InferenceOutput>;
     ```

    As we can see, a side effect of the raw pointers is that the argument list grows in its length
    quickly, but there's very little I can do, since there must be some conversion between the
    `ndarray` types and memory buffers.

---

[^1]: In practice, the policy network and the value network are always tied together, sharing a large
    portion of the layers.
    I see this as a basic form of regularization - since the weights are tied, the network could
    be restricted to learn more useful information that affects both the scoring and policy.
