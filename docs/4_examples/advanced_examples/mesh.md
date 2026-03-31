# Mesh interconnect

This example builds a parameterized N×M toroidal mesh network. Each node performs a unit of compute work every cycle, then injects a packet to a randomly chosen destination every few cycles. In-transit packets are routed hop-by-hop using dimension-order (XY) routing: each intermediate node forwards the packet East until it reaches the correct column, then South until it reaches the correct row.

**What this example demonstrates:**

- Two-dimensional `submodule_array node[N][M]` declarations
- Two-dimensional `net_array net_e[N][M]` and `net_s[N][M]` declarations
- Nested structural `for` loops for 2D connection generation
- Wrap-around (toroidal) connections with explicit per-case for loops
- Parent `init` block initializing per-instance member variables (`row`, `col`) across a 2D array
- C++ pointer arrays (`inport<W>*`, `outport<W>*`) for indexed port access inside code blocks

---

## Topology

Each node has one East outport (`out_e`) and one South outport (`out_s`), plus matching inports (`in_e` receiving East-going tokens, `in_s` receiving South-going tokens). All connections wrap around — the rightmost column's East output connects to the leftmost column's East input, and the bottom row's South output connects to the top row's South input — forming a torus. Every node therefore always has a valid East and South neighbor, which simplifies the connection code and the routing logic.

---

## Mesh structure

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_mesh.sitar:structure"
```

Key structural features:

**2D `submodule_array`:** `submodule_array node[N][M] : MeshNode<N,M,INJECT_EVERY,RUN_CYCLES>` creates an N×M grid of `MeshNode` instances. Elements are accessed as `node[i][j]`.

**2D `net_array`:** `net_array net_e[N][M] : capacity 2 width 12` creates a 2D array of nets. East-going token from node[i][j] travels on `net_e[i][j]`; South-going on `net_s[i][j]`.

**Nested `for` loops:** Connection statements inside nested `for i ... for j ... end for end for` blocks generate all interior connections. The wrap-around connections (last column → first column, last row → first row) are handled by separate single-dimension loops without requiring modulo arithmetic in the index expressions.

**Parent `init` block:** Since all `MeshNode` instances share the same type and template arguments, their `row` and `col` positions cannot be passed as compile-time parameters. The parent sets them at construction time using a C++ nested loop in the `init` block:

```sitar
init $
for (int i = 0; i < N; i++)
    for (int j = 0; j < M; j++) {
        node[i][j].row = i;
        node[i][j].col = j;
    }
$
```

---

## Node behavior

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_mesh.sitar:node"
```

**Phase 0 — receive:** Each node accepts at most one incoming packet per cycle. If the packet is destined for this node, it is consumed and logged. Otherwise it is held in the node's transit slot.

**Phase 1 — forward or inject:** If the transit slot holds a packet, the node forwards it one hop toward its destination. XY routing: move East while `pkt_dc != col`; then South. If the target net is full, the packet is held and retried next cycle. If the transit slot is empty and it is an injection cycle, the node generates a new packet to a random destination.

!!! note "One packet in transit per node"
    This model allows at most one forwarded packet per node per cycle. A production router would maintain per-direction queues; this example keeps the behavior minimal to focus on structural constructs.

---

## Expected output (3×3 mesh, 20 cycles)

```
(0,1) TOP.mesh.node[0][0] : (0,0) inject to (2,1)
(0,1) TOP.mesh.node[0][0] : (0,0) fwd E to (2,1)
(1,0) TOP.mesh.node[0][1] : (0,1) fwd E to (2,1)
(2,0) TOP.mesh.node[0][2] : (0,2) fwd S to (2,1)
(3,0) TOP.mesh.node[1][2] : (1,2) fwd S to (2,1)
(4,0) TOP.mesh.node[2][1] : (2,1) consumed data=0
...
Simulation stopped at time (20,0)
```

Each packet takes at most N+M−2 hops. With a 3×3 mesh the longest path is 4 hops. Multiple packets circulate concurrently; their interleaved log lines show the hop-by-hop traversal.

!!! tip "Scaling the mesh"
    Change the top-level instantiation to `Mesh<4,4>` or `Mesh<8,8>` to generate larger meshes. The structure, connection loops, and routing logic are all parameterized on N and M — no other changes are needed.

---

## Full example

The complete model below is self-contained and runnable. The `Top` module instantiates a 3×3 mesh; change the template arguments to scale up.

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_mesh.sitar:top"
```

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_mesh.sitar:structure"
```

``` sitar linenums="1"
--8<-- "docs/sitar_examples/4_mesh.sitar:node"
```
