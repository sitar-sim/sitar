from setuptools import setup, find_packages

setup(
    name="sitar-mkdocs-lexer",
    version="0.1.0",
    description="Pygments lexer for the Sitar language",
    packages=find_packages(),
    entry_points={
        "pygments.lexers": [
            "sitar=sitar_pygments_lexer.sitar:SitarLexer",
        ]
    },
    install_requires=["Pygments>=2.3"],
)

