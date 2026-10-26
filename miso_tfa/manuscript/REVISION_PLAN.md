# Manuscript revision status

The current draft intentionally stops after Results. It tells one continuous
story from the physiological question, through known-truth simulation, to a
separate held-out analysis of NC recordings.

## Completed without rerunning the simulation

1. Replaced the original overview with a detailed workflow that shows signal
   generation, recording effects, SISO/MISO estimation, known-truth comparison,
   and the separate NC prediction branch.
2. Added a figure showing the NC spectra and the fitted input-spectrum shape
   used by the simulator.
3. Replaced “signal family” with a condition-and-replicate hierarchy and added
   a diagram showing 500 paired repetitions and the bootstrap calculation.
4. Defined power, power spectra, SNR, transfer-function recovery error, and
   MISO advantage before using them.
5. Declared the one-factor-at-a-time reference settings in the Methods, design
   table, figure titles, and captions.
6. Kept MAP-pathway and CO2-pathway recovery separate.
7. Combined MAP noise, CO2 noise, and CO2 alignment into one recording-
   sensitivity figure; moved MAP–CO2 timing to one coherent three-panel figure.
8. Reduced the NC figure to the measured 23-subject result. The manuscript now
   reports that all 30 point estimates favored MAP-only SISO, 26 pointwise
   intervals were entirely below zero, and 4 included zero.
9. Removed the analytic-check and white-output-noise figures from the main
   Results sequence. Their saved numerical outputs remain available as
   diagnostics.
10. Regenerated all manuscript assets and the canonical PDF exclusively from
    the frozen final-study files.

## Decisions that require scientific discussion before another simulation

- Decide whether coherence 0.50 should remain the moderate reference test
  condition or whether the primary reference should move to the NC-informed
  coherence level of 0.15.
- Decide whether the pathway ratio and 10-dB output SNR levels need stronger
  physiological justification or should remain declared mechanism and
  recording-quality test conditions.
- Decide whether CO2 alignment error should remain a main sensitivity factor
  or move to a secondary robustness analysis.
- Decide whether the white-output-noise diagnostic needs a brief Results
  statement after its scientific interpretation is reviewed.

Changing any of those conditions would require a planned rerun. Wording,
figure order, captions, and interpretation can continue to be revised from the
current frozen outputs.

## Remaining writing

- Review each Results claim against its heatmap with the study team.
- Revise the abstract only after that interpretation is accepted.
- Add Discussion, limitations, and conclusion.
- Adapt the manuscript to a target journal after the scientific story is
  stable.

## Reproducible build

From `miso_tfa`, run:

```matlab
restoredefaultpath
setup
buildManuscript
```

This writes the canonical PDF to
`output/pdf/MISO_TFA_simulation_study_manuscript.pdf` without rerunning the
simulation.
