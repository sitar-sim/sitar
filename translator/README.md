# Translator

This folder contains:

- **`antlrworks-1.5.jar`** -- ANTLR GUI editor for viewing the grammar.
- **`antlr3Cruntime`** -- installation folder for the ANTLR3 C runtime, v3.4.
- **`grammar`** -- ANTLR grammar for Sitar and the output-generation template.
- **`parser`** -- ANTLR-generated parser/lexer and wrapper code for using them.

The Sitar translator has been created using the [ANTLRv3 tool](http://www.antlr3.org/download.html) (with C runtime):

- ANTLRWorks version 1.4.3
- C runtime version 3.4

## Viewing/editing the Sitar grammar and translator

1. Install Java (JDK version 6/7).
2. Launch ANTLRWorks:
   ```sh
   java -jar antlrworks-1.4.3.jar
   ```
   or use the shortcut defined in your `.bashrc`:
   ```sh
   antlrworks
   ```
3. Open the grammar files:
   - `./grammar/sitar.g`, or
   - `./grammar/output_template.g`
4. In `File -> Preferences -> General`, set the output path as `./parser`, then click `Generate -> Generate Code` to generate code for the lexer and parser.

   Alternatively, without the GUI (e.g. no display available): the jar also bundles ANTLR3's underlying command-line generator, `org.antlr.Tool`, which can be invoked directly:
   ```sh
   cd grammar
   java -cp ../antlrworks-1.4.3.jar org.antlr.Tool -o ../parser/antlr_generated sitar.g
   ```
   (use `output_template.g` instead of `sitar.g` to regenerate that lexer/parser).
5. Run `scons` in the `./parser` folder to generate the translator executable.
6. To test the translator, run it on Sitar descriptions in the `examples` folder.
