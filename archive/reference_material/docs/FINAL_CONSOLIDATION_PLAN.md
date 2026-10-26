# Final MISO-TFA consolidation plan

This plan turns the reviewed platform into one independent MATLAB subproject.
The new subproject becomes the only active workflow. The current top-level
folders remain migration sources until the new tree passes its tests and its
dependency audit. Deletion is the last step, not the mechanism used to discover
what is still needed.

## Target boundary

The active project will live under `miso_tfa/` and will run from its own
`setup.m`. A user should be able to copy that folder into a clean MATLAB
session, call `setup`, and run the six public pages without adding the old
repository `src`, `studies`, `main.m`, or `model_generator` folders.

```text
miso_tfa/
├── README.md
├── setup.m
├── interfaces/
│   ├── connectData.m
│   ├── misoTesting.m
│   ├── sisoTesting.m
│   ├── ncBootstrap.m
│   ├── simulationSettings.m
│   └── runSimulation.m
├── config/
│   ├── projectSettings.m
│   ├── simulationFactors.m
│   ├── realDataSettings.m
│   └── validateSettings.m
├── modules/
│   ├── data/
│   ├── preprocessing/
│   ├── tfa/
│   ├── phase/
│   ├── simulation/
│   ├── validation/
│   └── reporting/
├── tests/
├── examples/
├── docs/
└── output/
```

The six interface files are the only normal user entry points. Exporting is an
optional output argument of each relevant page, not a separate user workflow.
The `modules` folder contains plain MATLAB functions and remains readable; no
class framework is required.

## Scientific specification to lock before final figures

The primary simulation factors will be:

1. MAP-CO2 input coherence.
2. MAP-CO2 input phase lag.
3. Relative CO2 contribution to CBFV.
4. Recording duration.
5. CBFV output SNR.
6. MAP measurement SNR.
7. CO2 measurement SNR.

CO2 measurement misalignment becomes a secondary robustness analysis. Welch
window settings, spectral similarity, input fluctuation-SD ratio, and pathway
delay remain fixed in the primary study unless a later sensitivity analysis
requires them.

The main estimand remains conditional pathway error: MISO and SISO are compared
on recovery of the separate MAP and CO2 pathways. SISO's omitted-variable bias
is an intended part of the comparison and will be described explicitly. A
secondary diagnostic may report SISO's own population target, but it will not
replace the primary comparison.

The sampling rate is 4 Hz, giving a 2 Hz Nyquist frequency. The physiological
reporting band will end at 0.35 Hz. A fixed pathway-calibration band will be
stored separately from the reporting range so changing a plot cannot change the
generated truth. The exact lower bound will be fixed in the protocol after the
Welch resolution and NC bandwidth review.

The primary outputs remain frequency-by-metric advantage heatmaps. Coherence
diagnostics are secondary quality-control quantities with empirical null
references; they are not additional headline outcomes.

Ridge regularization is removed from the active simplified workflow. Its old
sensitivity code can remain outside the new tree until the migration is
complete. If it is retained later, it must be tested as an optional diagnostic,
not treated as a primary study factor.

## Implementation stages

### Stage 1 — independent project shell

- Create `miso_tfa/` with `setup.m`, interfaces, modules, tests, examples,
  documentation, and ignored output.
- Copy only the transitive active dependencies of the six public pages.
- Replace `setupPlatform` calls with the new local setup function.
- Make Git-state and manifest discovery resolve to the subproject root.
- Add a dependency check that fails if an active file resolves outside
  `miso_tfa/`.

Acceptance: a clean MATLAB session can run every interface after only calling
`miso_tfa/setup`.

### Stage 2 — one configuration source

- Add one project settings entry point.
- Add a factor table containing level, units, rationale, and provenance for
  every varied factor.
- Remove duplicated defaults from the active path.
- Rename the settings constructor so a settings value is not confused with a
  function of the same name.
- Make the fixed reporting and calibration bands explicit.

Acceptance: the active simulation protocol can be generated from the settings
structure and no active file defines a competing frequency range or factor
list.

### Stage 3 — simulation and estimand corrections

- Add MAP-CO2 input phase lag before CBFV generation.
- Keep conditional pathway error as the primary score.
- Add the optional SISO-population-target diagnostic.
- Generate each clean family once at the longest duration and truncate it for
  shorter observations.
- Use stable independent random streams for family, observation-noise, and
  bootstrap seeds.
- Add replay from a saved manifest.
- Remove ridge outputs and ridge configuration from the active simulation.

Acceptance: changing duration lists or the number of families does not redraw
previously defined families, and a saved run replays to the same source tables.

### Stage 4 — measurement-noise and diagnostic design

- Separate CBFV output noise from MAP measurement noise and CO2 measurement
  noise.
- Add the three SNR factors to the observation design.
- Keep alignment as a separate robustness experiment.
- Store raw coherence and an empirical null reference.
- Keep coherence diagnostics out of the primary advantage figure unless they
  directly support interpretation.

Acceptance: every output metric has one definition, one unit, and one stated
role in the paper.

### Stage 5 — NC validation corrections

- Mask frequencies above each subject's usable Nyquist frequency.
- Separate acquisition cleanup from training-only analysis conditioning.
- Keep held-out prediction advantage distinct from simulation truth error.
- Decide whether the two-training-segment design is presented as a powered
  test or a workflow demonstration.

Acceptance: the NC report does not claim support for frequencies or inference
that the individual records cannot provide.

### Stage 6 — import and preprocessing hardening

- Support CSV as well as Excel.
- Make column matching case-insensitive and whitespace-tolerant.
- Add explicit column-map overrides.
- Add units and plausibility checks.
- Add maximum-gap and maximum-CO2-startup-trim settings.
- Report missingness, interpolation, startup trimming, retained duration, and
  usable bandwidth in the result status.

Acceptance: a user who supplies a file path receives either a canonical data
object or an actionable error naming the available columns and assumptions.

### Stage 7 — tests and documentation

- Add tests for correlated-input recovery at multiple coherence levels.
- Add tests for phase-lag recovery.
- Add tests for short and long data gaps.
- Add a saved-run replay test.
- Add tests for separate MAP, CO2, and CBFV noise.
- Rewrite the README around `miso_tfa/`.
- Move the Claude review artifacts under `docs/reviews/` or remove them after
  their findings are incorporated.
- Remove tracked `tmp/` content and add it to `.gitignore`.

Acceptance: the independent project has a complete test command and a README
that describes only the active workflow.

### Stage 8 — retirement of the old tree

- Tag the last pre-consolidation commit.
- Run the new subproject tests and dependency audit.
- Confirm that all figures and tables needed by the paper are produced by the
  new workflow.
- Remove the old platform façade, approach-paper workflow, legacy plotting and
  output paths, and unused model-generator material in one deliberate commit.
- Re-run tests and check for references to deleted paths.

Acceptance: the active project runs entirely from `miso_tfa/`, and every file
outside it is either documentation, manuscript material, or explicitly marked
historical.
