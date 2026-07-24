# Examples

This folder contains simple examples of Sitar descriptions. Each example illustrates a construct in the language.

For each description, a user has to first translate the Sitar description into C++ code, and then compile the code along with the Sitar core classes to obtain a simulation executable.

## Running the `0_HelloWorld.sitar` example

```sh
sitar translate 0_HelloWorld.sitar
sitar compile
./sitar_sim
```

For detailed information on translation and compilation options:

```sh
sitar translate -h
sitar compile -h
```
