# Manuscript Difference Report

This report compares the three document states before any blue-text merge is performed. The comparison uses the accepted/current visible text of each DOCX and separately records the tracked revisions and comments stored in the package.

## Files used

| Role | File | Reason |
|---|---|---|
| Original draft | `Development and Validation of a Two.docx` | Untracked draft created before Sho's returned revision |
| Sho baseline | `Development and Validation of a Two_Sho_revised.docx` | Returned file containing Sho's tracked edits and comments |
| Current working manuscript | `sho_misotfa.docx` | Formatted manuscript containing Sho's revisions plus later Amogh revisions |
| Excluded later file | `Development and Validation of a Two_Ssho.docx` | Later combined revision; it contains Amogh-tracked insertions and is not the clean Sho baseline |

## Document-level comparison

| Document | Visible paragraphs | Visible characters | Tracked insertions | Tracked deletions | Comments | Tables | Equations | Images |
|---|---:|---:|---|---|---|---:|---:|---:|
| Original draft | 18 | 8,780 | 0 | 0 | 0 | 0 | 0 | 0 |
| Sho baseline | 20 | 11,368 | 祥太郎 齋藤: 36 | 祥太郎 齋藤: 5 | 祥太郎 齋藤: 3 | 0 | 0 | 0 |
| Current working manuscript | 128 | 31,255 | Naganand, Amogh: 54; 祥太郎 齋藤: 36 | Naganand, Amogh: 47; 祥太郎 齋藤: 5 | 祥太郎 齋藤: 3; Naganand, Amogh: 7 | 11 | 7 | 3 |

## Original draft compared with Sho baseline

Sho kept the title and abstract structure, then replaced and expanded the opening of the Introduction. The original opening was a single paragraph beginning with the brain's need for continuous blood flow. Sho's version begins with the importance of cerebral blood-flow regulation, explicitly introduces arterial pressure and arterial CO₂, defines cerebral autoregulation, and then adds a separate paragraph distinguishing static from dynamic autoregulation.

The remainder of the introduction follows the same overall scientific direction as the draft: MAP-only SISO analysis, the role of CO₂, prior multivariable work, the distinction between output prediction and pathway recovery, the MISO model, NC recordings, and known-truth simulation. Sho's returned file contains 36 tracked insertions, 5 tracked deletions, and 3 comments.

### Representative changed opening

- Paragraphs 8–8: The brain requires continuous blood flow even as arterial pressure changes from beat to beat. Cerebral autoregulation describes the physiological processes that limit how strongly these pressure changes alter cerebral perfusion (Regulation of Cerebral Blood Flow in Humans). Dynamic cerebral autoregulation focuses on responses that occur over seconds to minutes. TFA is commonly used to study these responses by treating MAP as the input and CBFV as the output (Transfer Function Analysis of Dynamic
+ Paragraphs 8–10: Adequate regulation of cerebral blood flow (CBF) is essential for normal brain function. Among the multiple mechanisms involved in CBF regulation, responses to changes in arterial blood pressure and the partial pressure of arterial carbon dioxide (PaCO₂) are particularly important. Cerebral autoregulation (CA) refers to the ability of the cerebral vasculature to buffer the effects of changes in arterial blood pressure on CBF. In response to an increase in blood pressure, cerebrovascular constriction occurs, thereby limiting excessive cerebral perfusion. In contrast, a decrease in blood pressure evokes cerebral vasodilation to protect against cerebral hypoperfusion. Cerebral vasomotor CO₂ rea

## Sho baseline compared with the current working manuscript

The current working manuscript is a substantially expanded paper rather than a small wording revision. It preserves Sho's returned Introduction material in tracked form, but adds the new manuscript structure, the Methods section, equations, figures, table, MATLAB excerpts, simulation-design explanations, and the current references.

The main visible changes are:

- The title is revised to identify blood pressure, CO₂, and cerebral blood flow dynamics explicitly.
- The abstract is intentionally deferred while the Results and interpretation are finalized.
- The Introduction is rewritten and expanded to explain frequency-domain TFA, SISO versus MISO, coherence, pathway interpretation, simulation logic, and the two accuracy questions.
- Methods are added to describe the known-truth simulation, signal-family construction, input dependence, pathway responses, noise, timing, estimation, accuracy metrics, NC validation, and reproducibility controls.
- Three figures, one design table, seven native Word equations, and MATLAB code excerpts are present in the working manuscript.
- The working file contains Sho's 36 insertions and 5 deletions plus 54 Amogh insertions and 47 Amogh deletions. It also contains the preserved comment threads and replies.

### Representative structural change

- Paragraphs 1–6: Development and Validation of a Two-Input Transfer Function Analysis for Cerebral Blood Flow Dynamics Abstract Background and Aim: Transfer Function Analysis (TFA) of dynamic cerebral autoregulation (dCA) commonly treats mean arterial pressure (MAP) as the single input affecting cerebral blood flow velocity (CBFV), although end-tidal carbon dioxide (PETCO₂) can also influence CBFV. When MAP and PETCO₂ fluctuate together, separate single-input-single-output (SISO) estimates may not distinguish th
+ Paragraphs 1–2: Development and Validation of a Two-Input Transfer Function Analysis for Blood Pressure, CO₂, and Cerebral Blood Flow Dynamics Abstract deferred until the results and interpretation are finalized.
- Paragraphs 8–20: Adequate regulation of cerebral blood flow (CBF) is essential for normal brain function. Among the multiple mechanisms involved in CBF regulation, responses to changes in arterial blood pressure and the partial pressure of arterial carbon dioxide (PaCO₂) are particularly important. Cerebral autoregulation (CA) refers to the ability of the cerebral vasculature to buffer the effects of changes in arterial blood pressure on CBF. In response to an increase in blood pressure, cerebrovascular constric
+ Paragraphs 4–128: Adequate regulation of cerebral blood flow (CBF) is essential for normal brain function. Among the multiple mechanisms involved in CBF regulation, responses to changes in arterial blood pressure and the partial pressure of arterial carbon dioxide (PaCO₂) are particularly important. Cerebral autoregulation (CA) refers to the ability of the cerebral vasculature to buffer the effects of changes in arterial blood pressure on CBF. In response to an increase in blood pressure, cerebrovascular constriction occurs, thereby limiting excessive cerebral perfusion. In contrast, a decrease in blood pressure evokes cerebral vasodilation to protect against cerebral hypoperfusion. Cerebral vasomotor CO₂ rea

## Baseline copy prepared for verification

A duplicate of Sho's baseline was created at `/Users/amoghn/MATLAB/1) IEEM Cerebrovascular Project/1) TFA MISO/Cerebral-Hemodynamics-MISO-TFA/miso_tfa/manuscript/review/sho_revision_20260917/sho_revised_baseline_no_tracking.docx`. Existing Sho revisions and comments remain in that file, but the settings that tell Word to track future edits were removed. No Sho revision was accepted or rejected, and no blue-text merge has been applied. The copy has {'祥太郎 齋藤': 36} tracked insertions, {'祥太郎 齋藤': 5} tracked deletions, and {'祥太郎 齋藤': 3} comments, matching the Sho baseline.

The next controlled step is to have you verify the two comparison sections. After that, the new material from the current working manuscript can be copied into this baseline as blue text, while Sho's original tracked revisions remain redline revisions.

