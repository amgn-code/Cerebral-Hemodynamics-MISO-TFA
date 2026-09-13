# MISO-TFA paper draft v2

- `main.tex` is the self-contained manuscript source.
- `build/` contains generated LaTeX files and is ignored by Git.
- `output/` contains reviewed manuscript PDFs.

Open `main.tex` and run the default LaTeX Workshop recipe, or run the following
from this folder:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

The local `.latexmkrc` keeps all generated files in `build/`.
