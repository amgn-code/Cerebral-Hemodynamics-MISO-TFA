# Archived project material

The active software and current manuscript live entirely in `miso_tfa/`.
Nothing in this folder is required by `miso_tfa/setup.m`, the user interfaces,
the active tests, or the manuscript build.

## Categories

- `reference_material/` contains earlier manuscripts, protocol drafts, review
  records, presentations, model-generation experiments, old figures, and
  example data.
- `scratch/` contains temporary document-editing and rendering work.
- `generated_outputs/` contains large or superseded generated MATLAB outputs
  that are retained for provenance but are not needed for routine use.

The moved top-level folders have one clear reason for being here:

| Archived folder | Why it is retained |
| --- | --- |
| `reference_material/docs` | protocol drafts, reviews, and design evidence |
| `reference_material/review` | model and implementation review records |
| `reference_material/manuscript` | earlier paper drafts and writing experiments |
| `reference_material/slides` | historical presentations and their source figures |
| `reference_material/model_generator` | the abandoned learned-signal-generation idea |
| `reference_material/figures` | figures from superseded workflows |
| `reference_material/data` | legacy sample data and templates |
| `scratch/tmp` | temporary document and PDF editing work |

The active project has one entry point: start MATLAB in `miso_tfa`, run
`setup`, then use the functions documented in `miso_tfa/README.md`. The
current manuscript is built with `miso_tfa/buildManuscript` and reads the
frozen summary exports in `miso_tfa/output/final`.

Archive files are retained for historical context. They are not runtime
dependencies and should not be added back to the MATLAB path.
