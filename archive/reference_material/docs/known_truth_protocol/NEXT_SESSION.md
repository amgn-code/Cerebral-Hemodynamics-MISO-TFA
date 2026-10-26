# Next session: simplify before implementation

User direction, 13 September 2026. This handoff takes priority over the broader scope in the current proposal. No scientific MATLAB changes were made in this turn.

## Scientific scope

- Embed Shotaro's suggestions in the simulation's normal diagnostics and interpretation. Do not create a separate Shotaro workstream or expand the paper around extra metric families.
- Aim for 5-7 understandable recording conditions or analysis parameters in total. This is a limit on scientific breadth, not a request for a full factorial over 7 dimensions.
- A provisional six-item shortlist is recording duration, MAP-CO2 input dependence, relative CO2 contribution, noise level, timing alignment, and Welch window length. This shortlist is an assistant suggestion, not a user-approved final design. Some are recording characteristics rather than directly adjustable acquisition controls.
- Define whether timing means changing the physiological input relationship before output generation or introducing measurement misalignment afterward. They answer different questions and must not be silently combined.
- Coherence gaps are measured diagnostics, not independently adjustable generator settings. Integrate Shotaro's gap in the same saved frequency-level results, without counting each coherence definition as a new experimental factor.
- Keep frequency on x, the chosen factor/diagnostic on y, and accuracy advantage as color. Frequency-collapsed results are synopses only.
- Keep the accuracy endpoint small and clear. Avoid mandatory six-panel metric grids, extra robustness studies, and a new analysis branch for every suggested diagnostic.
- Retain the known-truth generator. Learned generation remains deferred. The previously proposed real-data irrelevant-input controls can remain a later option, not another mandatory section in the core simulation story.
- Reproducibility requires transparent settings, saved truth, stable random draws and focused correctness checks. It does not require a general-purpose framework or exhaustive option handling.

## Coding style

The user explicitly prefers easy-to-read MATLAB, even if longer or less compact. Modularization should make the workflow easier to follow, not fragment it into many tiny helpers or layers of configuration and dispatch.

Before implementing, review the earliest repository versions to distinguish the user's original style from later assisted refactors. Prefer explicit variables, ordinary loops, readable intermediate calculations, MATLAB section headings, and short explanations of purpose. Use a few functions corresponding to recognizable scientific steps. Keep necessary validation near its inputs; avoid speculative configurability and redundant wrappers.

Local Git is not shallow and contains 40 commits reachable from HEAD. Historical files can be read using git show without checking out or overwriting current work. Relevant starting points:

- 099eb08, 2026-06-01: Initialization of Repo.
- 3b909e1, 2026-06-01: TFA Pipeline; main.m and runTFA.m available.
- 7efea66, 2026-06-11: Modularized.
- 589d68f, 2026-07-13: Before large rewrite.

Only main.m from 589d68f was sampled this turn: clear section headings, explicit settings, and straightforward if/elseif execution. Do not assume that every historical commit reflects the user's own preferred authorship; compare early versions before deciding conventions.

## First next-session deliverable

Revise the proposal into a short, coherent 5-7-item study, embedding Shotaro's diagnostics. Explain each item's physiological or practical meaning, why it is varied, what is held fixed, and its intended frequency-by-factor figure. Then implement only the first agreed chunk in the user's readable style. The current PDF is not yet revised for this latest scope reduction.

Preserve existing outputs. Previously identified error-normalization inconsistencies and coherence-definition checks still need resolution before new production simulations. No new MATLAB results have been generated.
