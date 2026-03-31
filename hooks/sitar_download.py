"""
on_page_markdown hook: append a download link after every ```sitar code fence
that contains a --8<-- snippet import from docs/sitar_examples/*.sitar.

No JavaScript required. The link is plain markdown rendered as a small line
immediately below the code block.
"""

import re
import os

# Matches a complete ```sitar fence whose first content line is a snippet
# include from docs/sitar_examples/FNAME.sitar (with optional :section suffix).
_FENCE_RE = re.compile(
    r'(?m)'
    r'^(?P<open>`{3,}[ \t]*sitar[^\n]*\n)'               # opening fence line
    r'(?P<include>[ \t]*--8<--[ \t]*"docs/sitar_examples/'
    r'(?P<fname>[^":\n]+\.sitar)[^"\n]*"[ \t]*\n)'        # snippet include line
    r'(?P<body>(?:.*\n)*?)'                                # remaining fence body (usually empty)
    r'(?P<close>^`{3,}[ \t]*\n)',                          # closing fence line
)


def _rel_url(page_src_path: str, sitar_fname: str) -> str:
    page_dir = os.path.dirname(page_src_path)
    target   = os.path.join("sitar_examples", sitar_fname)
    rel      = os.path.relpath(target, page_dir)
    return rel.replace(os.sep, "/")


def on_page_markdown(markdown: str, page, **kwargs) -> str:
    page_src = page.file.src_path

    def _replace(m: re.Match) -> str:
        fname   = m.group("fname")
        rel_url = _rel_url(page_src, fname)
        link    = f'<div class="sitar-dl-link"><a href="{rel_url}" download="{fname}">Download <code>{fname}</code></a></div>\n'
        return m.group(0) + link

    return _FENCE_RE.sub(_replace, markdown)
