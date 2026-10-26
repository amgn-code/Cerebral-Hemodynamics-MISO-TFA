# Cerebral Hemodynamics MISO-TFA

The active MATLAB project is the self-contained [`miso_tfa`](miso_tfa)
subfolder. Start MATLAB there and run:

```matlab
project = setup;
```

The standalone project provides three user workflows:

```matlab
data = connectData("/path/to/recording.xlsx");
miso = misoTesting(data);
siso = sisoTesting(data);

simulation = runSimulation(simulationSettings("simple"));

nc = ncBootstrap("/path/to/ieem_data");
```

The frozen research study is run separately so its core, phase, input-noise,
alignment, and noise-shape experiments cannot be mixed accidentally:

```matlab
output = defaultSimulationOutputSettings("off");
output.createFigures = false;
study = runFinalSimulationStudy(500, output);
exportFinalSimulationStudy(study, fullfile(pwd, "output", "final"));
```

Read [`miso_tfa/README.md`](miso_tfa/README.md) for usage,
[`miso_tfa/docs/WORKFLOW.md`](miso_tfa/docs/WORKFLOW.md) for the module flow,
and [`miso_tfa/docs/SIMULATION_PROTOCOL.md`](miso_tfa/docs/SIMULATION_PROTOCOL.md)
for the scientific design and interpretation limits.

The top-level `archive/` folder contains historical manuscripts, source
material, presentations, old figures, scratch work, and superseded generated
outputs. Nothing in `archive/` is a runtime dependency. The active project is
deliberately limited to `miso_tfa/`.

## Current manuscript

The simulation paper is inside the standalone project:
[`miso_tfa/manuscript`](miso_tfa/manuscript). From `miso_tfa`, run
`buildManuscript` to generate the descriptive manuscript PDF in `output/pdf`.
Earlier writing and source material is retained under
`archive/reference_material/manuscript/`.
