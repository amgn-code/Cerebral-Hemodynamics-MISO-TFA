# Known-truth simulation audit

Profile: `proof250`  
Evidence level: Presentation proof-of-concept evidence; not final-paper evidence.  
Elapsed numerical time: 21.3 minutes (1279.3 seconds)

This report checks design execution, numerical support, and checkpoint stability before any result narrative is written. Sparse realized-value cells are reported descriptively and are not automatically treated as design failures.

## Core execution checks

| Check | Observed | Expected | Pass |
|---|---:|---:|:---:|
| Named analysis profile | proof250 | quick, designSmoke, proof250, or paper1000 | yes |
| Configured family count | 250 | 250 | yes |
| Stored family count | 250 | 250 | yes |
| One characterization row per family | 250 | 250 | yes |
| Complete pairwise design blocks | 10 blocks | 10 complete blocks | yes |
| Assigned marginal balance | 25 of 25 | all factor levels | yes |
| Assigned pairwise balance | 250 of 250 | all factor-level pairs | yes |
| Primary observation count | 17000 | 17000 | yes |
| Stored primary observation count | 17000 | 17000 | yes |
| Ridge-analysis count | 750 | 750 | yes |
| Estimator-sensitivity count | 10750 | 10750 | yes |
| Minimum valid N by observation condition | 748 of 748 | all planned metric-condition groups | yes |
| Minimum valid N at stability checkpoints | 18 of 18 | all checkpoint metrics | yes |
| Elapsed time recorded | 1279.254 s | positive finite duration | yes |

## Assigned-factor balance

All 25 marginal level checks passed: **yes**. All 250 pairwise cell checks passed: **yes**.

## Realized-bin occupancy

| Characteristic | Minimum cell N | Maximum cell N | Cells meeting display minimum | Empty cells |
|---|---:|---:|---:|---:|
| Realized MAP-PETCO2 coherence | 49 | 51 | 5 of 5 | 0 |
| Realized PSD-shape overlap | 0 | 100 | 4 of 5 | 1 |
| Realized PETCO2 contribution-power share | 18 | 151 | 5 of 5 | 0 |
Across the joint realized-characteristic grids, 43 of 75 cells meet the prespecified display minimum and 13 cells are empty. These values measure support; fixed boundaries were not moved to improve occupancy.

## Validity audit

The retained observation table contains 748 metric-condition support checks. 748 meet the minimum valid-family rule; 0 do not. A total of 0 invalid metric values were retained as missing rather than silently discarded.

## Balanced-checkpoint stability

The following descriptive means compare complete balanced blocks. Change from final is the checkpoint mean minus the full-run mean; it is not a separate hypothesis test.

| Families | Blocks | Metric | Mean | SD | Valid N | Change from final |
|---:|---:|---|---:|---:|---:|---:|
| 125 | 5 | MAPComplexAdvantage | 0.31087 | 0.77368 | 125 | 0.023621 |
| 125 | 5 | MAPGainAdvantage | 0.16388 | 0.38849 | 125 | 0.0099889 |
| 125 | 5 | MAPPhaseAdvantage | 0.13944 | 0.34073 | 125 | 0.017514 |
| 125 | 5 | CO2ComplexAdvantage | 1.156 | 0.73232 | 125 | 0.033903 |
| 125 | 5 | CO2GainAdvantage | 0.65571 | 0.38877 | 125 | 0.011834 |
| 125 | 5 | CO2PhaseAdvantage | 0.24349 | 0.27508 | 125 | 0.0018632 |
| 200 | 8 | MAPComplexAdvantage | 0.30415 | 0.76216 | 200 | 0.016896 |
| 200 | 8 | MAPGainAdvantage | 0.1631 | 0.38262 | 200 | 0.0092025 |
| 200 | 8 | MAPPhaseAdvantage | 0.12543 | 0.33991 | 200 | 0.0035039 |
| 200 | 8 | CO2ComplexAdvantage | 1.1296 | 0.75052 | 200 | 0.0075792 |
| 200 | 8 | CO2GainAdvantage | 0.64142 | 0.40138 | 200 | -0.0024487 |
| 200 | 8 | CO2PhaseAdvantage | 0.24767 | 0.27163 | 200 | 0.0060438 |
| 250 | 10 | MAPComplexAdvantage | 0.28725 | 0.74584 | 250 | 0 |
| 250 | 10 | MAPGainAdvantage | 0.15389 | 0.37325 | 250 | 0 |
| 250 | 10 | MAPPhaseAdvantage | 0.12193 | 0.33327 | 250 | 0 |
| 250 | 10 | CO2ComplexAdvantage | 1.1221 | 0.75673 | 250 | 0 |
| 250 | 10 | CO2GainAdvantage | 0.64387 | 0.40229 | 250 | 0 |
| 250 | 10 | CO2PhaseAdvantage | 0.24163 | 0.25896 | 250 | 0 |

## Machine-readable audit tables

The corresponding detailed tables are exported to the `Tables` folder and the approach-paper workbook: overview, marginal balance, pairwise balance, one-dimensional realized occupancy, joint realized occupancy, observation validity, and checkpoint stability.
