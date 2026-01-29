# sitar_pygments_lexer/sitar.py

import re

from pygments.token import Generic
from pygments.lexer import RegexLexer, words
from pygments.token import (
    Keyword,
    Name,
    Comment,
    String,
    Number,
    Operator,
    Punctuation,
    Text,
    Generic,
)

class SitarLexer(RegexLexer):
    """
    Pygments lexer for the Sitar System Description Language (v2.0).
    Based on the original Vim syntax file by Neha Karanjkar.
    """

    name = "Sitar"
    aliases = ["sitar"]
    filenames = ["*.sitar"]
    mimetypes = ["text/x-sitar"]

    flags = re.MULTILINE | re.UNICODE

    tokens = {
        "root": [
            # Whitespace
            (r"\s+", Text),

            # Single-line comments (greenish in light themes)
            (r"//.*$", Comment.Single),

            # Code blocks: $ ... $  → Preprocessor (Vim-compatible)
            (r"\$", Generic, "codeblock"),

            # Strings
            (r'"', String, "string"),

            # Main keywords
            (
                words(
                    (
                        "module",
                        "procedure",
                        "parameter",
                        "behavior",
                    ),
                    suffix=r"\b",
                ),
                Keyword.Declaration,
            ),

            # Behavioral keywords
            (
                words(
                    (
                        "wait",
                        "until",
                        "if",
                        "then",
                        "else",
                        "do",
                        "while",
                        "nothing",
                        "stop",
                        "simulation",
                        "run",
                        "end",
                    ),
                    suffix=r"\b",
                ),
                Keyword,
            ),

            # Structural keywords
            (
                words(
                    (
                        "inport",
                        "inport_array",
                        "outport",
                        "outport_array",
                        "buffer",
                        "net",
                        "net_array",
                        "submodule",
                        "submodule_array",
                        "width",
                        "capacity",
                        "for",
                        "in",
                        "to",
                    ),
                    suffix=r"\b",
                ),
                Keyword.Type,
            ),

            # Other keywords
            (
                words(
                    (
                        "or",
                        "and",
                        "not",
                        "this_phase",
                        "this_cycle",
                    ),
                    suffix=r"\b",
                ),
                Keyword.Constant,
            ),

            # Code snippet keywords
            (
                words(
                    (
                        "include",
                        "decl",
                        "init",
                    ),
                    suffix=r"\b",
                ),
                Keyword.Preproc,
            ),

            # Numbers
            (r"\b\d+\b", Number.Integer),

            # Symbols / operators
            (r"<=|=>|:", Operator),

            # Statement connectors / punctuation
            (r";|\|\||\[|\]", Punctuation),

            # Identifiers
            (r"[A-Za-z_][A-Za-z0-9_]*", Name),

            # Anything else
            (r".", Text),
        ],

        # Double-quoted strings
        "string": [
            (r'"', String, "#pop"),
            (r'[^"\\]+', String),
            (r"\\.", String.Escape),
        ],
       "codeblock": [
            (r"\$", Generic, "#pop"),
            (r".|\n", Generic),
        ],
}

