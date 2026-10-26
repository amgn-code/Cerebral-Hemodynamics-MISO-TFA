# Long-form MISO-TFA presentation

This is the canonical VS Code project for the active long-form presentation.

## Contents

- `main.tex` — active 119-slide LaTeX source.
- `figures/methods/` — explanatory signal-processing figures.
- `figures/proof250/` — selected 250-family proof-of-concept figures.
- `figure_generators/` — reproducible method-figure generator.
- `source_material/proof250/` — audit notes, captions, manifests, and CSV source data.
- `build/` — generated LaTeX files; ignored by Git.
- `output/MISO_TFA_long_form_revised.pdf` — reviewed presentation PDF.
- `archive/` — superseded reviewed presentation exports.

## Current revision status

The active `main.tex` includes the approved long-form updates:

- clear explanations of family-figure panels E and F;
- explicit input–input and input–output labeling;
- separate MAP and PETCO2 gain/phase evaluation slides;
- the signed model-advantage interpretation;
- literature support for the known-truth signal generator;
- the main-paper versus supplement mathematical plan;
- full signal-construction, SISO-contamination, MISO, conditioning, and scoring derivations; and
- end-of-deck reference-bank slides.

The two metric-hierarchy planning slides are not in the active deck.

## Build

Open `main.tex` and run the default LaTeX Workshop recipe. VS Code writes all
generated files to `build/`.

From a terminal in this folder, run:

```sh
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

The local `.latexmkrc` also directs output to `build/`. After review, copy
`build/main.pdf` to the descriptive file in `output/`.

The `proof250` results are presentation proof-of-concept evidence, not the
planned final-paper simulation.
