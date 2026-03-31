
Todo:


1.  Simplify the net and port interconnection syntax, current:
    ```
    sender.outp   => n_forward    // sender's outport writes to n_forward
    receiver.inp  <= n_forward    // receiver's inport reads from n_forward
    ```

    Also support:
    ```
    sender.outp => n1 => receiver.inp
    ```

2. Support port mapping to preserve modularity.

    Currently:
    ```
    sender.outp => n
    receiver.child.inp <=n
    ```

    Replace with
    ```
    sender.outp =>n =>receiver.inp
    ```

    and inside Receiver, support a port mapping between its inp to child's inp:
    ```
    inp =>> child.inp
    child.outp =>> outp
    ```

3. Logo

4. Syntax highlighting and editor keymappings support for VSCODE, add to getting started in docs

5. 













