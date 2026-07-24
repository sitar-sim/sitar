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

Each node has one East outport (`out_e`) and one South outport (`out_s`), plus matching inports (`in_e` receiving East-going tokens, `in_s` receiving South-going tokens). All connections wrap around: the rightmost column's East output connects to the leftmost column's East input, and the bottom row's South output connects to the top row's South input. This forms a torus. Every node therefore always has a valid East and South neighbor, which simplifies the connection code and the routing logic.

---

## Mesh structure

``` sitar linenums="1"
--8<-- "docs_source/sitar_examples/4_mesh.sitar:structure"
```

Key structural features:

**2D `submodule_array`:** `submodule_array node[N][M] : MeshNode<N,M,INJECT_EVERY,RUN_CYCLES>` creates an N×M grid of `MeshNode` instances. Elements are accessed as `node[i][j]`.

**2D `net_array`:** `net_array net_e[N][M] : capacity 2 width 12` creates a 2D array of nets. East-going token from node[i][j] travels on `net_e[i][j]`. South-going token travels on `net_s[i][j]`.

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
--8<-- "docs_source/sitar_examples/4_mesh.sitar:node"
```

**Phase 0 (receive):** Each node accepts at most one incoming packet per cycle. If the packet is destined for this node, it is consumed and logged. Otherwise it is held in the node's transit slot.

**Phase 1 (forward or inject):** If the transit slot holds a packet, the node forwards it one hop toward its destination. XY routing: move East while `pkt_dc != col`. Then South. If the target net is full, the packet is held and retried next cycle. If the transit slot is empty and it is an injection cycle, the node generates a new packet to a random destination.

!!! note "One packet in transit per node"
    This model allows at most one forwarded packet per node per cycle. A production router would maintain per-direction queues. This example keeps the behavior minimal to focus on structural constructs.

---

## Expected output (3×3 mesh, 20 cycles)

```
(0,1)TOP.mesh.node[2][1]:(2,1) inject to (0,0)
(1,1)TOP.mesh.node[2][2]:(2,2) fwd E to (0,0)
(2,1)TOP.mesh.node[2][0]:(2,0) fwd S to (0,0)
(3,0)TOP.mesh.node[0][0]:(0,0) consumed data=7
...
Simulation stopped at time (20,0)
```

The trace above shows a 3-hop path: node (2,1) injects a packet for (0,0). XY routing first moves it East: (2,1)→(2,2)→(2,0) (wrap-around, 2 East hops because the routing always moves East rather than West). It then takes one South hop via the toroidal wrap-around (row 2 to row 0). The `data=7` payload is the source node's linear index (2×3+1=7). Multiple packets circulate concurrently. Inject and forward events are logged in phase 1, consume events in phase 0. With a 3×3 mesh, the longest path under non-minimal XY routing is N+M-2 = 4 hops.

!!! tip "Scaling the mesh"
    Change the top-level instantiation to `Mesh<4,4>` or `Mesh<8,8>` to generate larger meshes. The structure, connection loops, and routing logic are all parameterized on N and M. No other changes are needed.

---

## Full example

The complete model below is self-contained and runnable. The `Top` module instantiates a 3×3 mesh. Change the template arguments to scale up.

``` sitar linenums="1"
--8<-- "docs_source/sitar_examples/4_mesh.sitar:top"
```

``` sitar linenums="1"
--8<-- "docs_source/sitar_examples/4_mesh.sitar:structure"
```

``` sitar linenums="1"
--8<-- "docs_source/sitar_examples/4_mesh.sitar:node"
```
