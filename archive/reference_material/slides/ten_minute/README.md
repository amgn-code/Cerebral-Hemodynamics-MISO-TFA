# Ten-minute MISO-TFA presentation

- `main.tex` is the short-talk Beamer source.
- `figures/` is the document-specific figure directory.
- `build/` contains generated LaTeX files and is ignored by Git.
- `output/` contains reviewed presentation PDFs.

Open `main.tex` and run the default LaTeX Workshop recipe, or run the following
from this folder:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

The source intentionally renders visible placeholders when its expected result
images are absent. The required filenames are listed at the top of `main.tex`.
