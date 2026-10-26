# Figure guide

`buildManuscript` creates these figures from the frozen numerical outputs. It
does not rerun the simulation. The order below follows the manuscript.

## Study workflow

![Study workflow](figures/figure1_study_design.png)

The upper branch shows the known-truth simulation from assigned conditions to
pathway-recovery error. The lower branch shows the separate held-out NC
prediction analysis.

## NC input spectrum used by the simulation

![NC input spectrum](figures/figure3_nc_input_spectrum.png)

The points show subject-median MAP and CO2 power. The mean curve and fitted
shape disclose how the input spectrum used by the simulation was chosen.

## Simulation repetitions

![Simulation repetitions](figures/figure2_simulation_replicates.png)

This explains the condition, replicate, paired-estimator, and bootstrap levels
without relying on the earlier ambiguous term “signal family.”

## Primary MAP-pathway results

![MAP primary factors](figures/figure2_map_primary_factors.png)

Each panel varies one named quantity. Frequency is horizontal, the tested
level is vertical, and color is MISO advantage. The fixed settings are stated
in the manuscript caption.

## Primary CO2-pathway results

![CO2 primary factors](figures/figure3_co2_primary_factors.png)

These panels use the same one-factor-at-a-time slices as the MAP figure but
compare MISO with CO2-only SISO.

## Recording sensitivity

![Recording sensitivity](figures/figure4_phase_and_robustness.png)

MAP input noise, CO2 input noise, and CO2 alignment are varied separately at
the declared reference test condition.

## Timing sensitivity

![Timing sensitivity](figures/figure7_phase_levels.png)

MAP–CO2 lag is varied at three coherence levels. This prevents timing effects
from being interpreted without considering input dependence.

## Held-out NC validation

![NC validation](figures/figure5_nc_validation.png)

The line is the measured NC advantage and the shaded region is its pointwise
95% subject-bootstrap interval. The former synthetic comparison panel is not
part of the manuscript figure.

The older analytic-check and white-output-noise PNG files are retained only as
saved diagnostic assets. They are not manuscript figures or additional study
endpoints.
