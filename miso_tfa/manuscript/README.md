# MISO-TFA simulation and NC validation manuscript

This is a manuscript draft for the known-truth simulation and held-out NC
validation study. It is intentionally separate from the earlier clinical
NC-versus-MCI manuscript.

This folder contains the manuscript source and the MATLAB-generated figure
assets. The paper is intended to be read from the compiled PDF, not from the
raw `.tex` file alone. The PNG files used by each figure are in `figures/`.

The figures and numerical macros are generated from the frozen outputs in
`miso_tfa/output/final`. From MATLAB, run exactly:

```matlab
cd("/path/to/Cerebral-Hemodynamics-MISO-TFA/miso_tfa")
restoredefaultpath
setup;
buildManuscript;
```

The canonical PDF is:

```text
miso_tfa/output/pdf/MISO_TFA_simulation_study_manuscript.pdf
```

`buildManuscript` regenerates the figures and tables, then compiles the LaTeX
source in one step. It reads the saved final study outputs and does not rerun
the simulation. The manuscript currently ends after the Results section. The
primary simulation figures use one-factor-at-a-time slices from the frozen
factorial results, and each caption states the settings held fixed. The paper
keeps NC held-out prediction separate from known-truth pathway recovery.

Start with `FIGURE_GUIDE.md` for a visual index. The older analytic-check and
white-output-noise images are diagnostic outputs and are not included in the
main paper.

The current build was verified with MATLAB R2025b and the local `latexmk`
toolchain. The frozen numerical exports in `miso_tfa/output/final` are the
source of the reported values; editing the manuscript does not regenerate or
refit those results.

## Word working drafts

The current advisor-facing Methods-only draft is
`Development and Validation of a Two-Input TFA — Methods Revision (Word).docx`.
It was built from Sho's `/Users/amoghn/Downloads/Development and Validation of a Two_Sho.docx`
review baseline, then saved through Word so the document opens normally. Sho's
three original comments remain in the file and each has a threaded reply. The
abstract, Results, and final conclusion are intentionally deferred until the
results and interpretation are settled.

The Introduction uses Times New Roman and bolds only selected revised claims;
it is not fully bold. Methods use readable subheadings, native editable Word
equations, the study-design and family-realization figures, the factor table,
and three short MATLAB excerpts. `INTRO_CONTENT_DISPOSITION.md` records where
the source Introduction material was retained or moved. `SOURCE_AUDIT.md`
records the local papers reviewed, the references used in the draft, and which
simulation choices remain explicit study-design assumptions.

The reproducible generator is
`tmp/word_migration/build_word_manuscript.py`. It creates the intermediate
`Development and Validation of a Two-Input TFA — Methods Revision.docx`; the
`(Word)` copy is the review file after Word has normalized the package and the
comment replies were posted. A rendered PDF is kept only under
`tmp/word_migration/` for visual QA and is not the manuscript source.
