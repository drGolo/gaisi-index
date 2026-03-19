# Index Construction: GAISI / GAIEI

## Overview

The **Generative AI Individual Susceptibility Index (GAISI)** are job and occupation-level measures of how susceptible an occupation's task bundle is to augmentation by large language models (LLMs). Definitions of susceptibility draw on Eloundou et al. (2024)'s *GPTs are GPTs* framework. The indices aggregate task-level LLM exposure probabilities to the occupation level using task importance weights.

---

## 1. Task-Level Exposure Classification

Each task is classified into one of four exposure levels following Eloundou et al. (2024):

| Level | Label | Definition |
|-------|-------|-----------|
| E0 | No exposure | LLM is unlikely to reduce task completion time by ≥25% |
| E1 | Direct exposure | Using an LLM via chat interface (e.g. ChatGPT) reduces task time by ≥25% |
| E2 | Integrated exposure | An LLM embedded in software or hardware (e.g. a Copilot tool) reduces task time by ≥25% |
| E3 | Image exposure | LLM-based image generation/analysis reduces task time by ≥25% |

Rather than a single hard classification, each LLM assigns a **probability distribution** over E0–E3 for each task (probabilities sum to 1). Multiple independent LLM runs are averaged to produce consensus probabilities.

> E3 is combined with E2 in the final indices (`final_e2 = E2 + E3`) because image-based capabilities are typically accessed through integrated tools.

---

## 2. Index Formula

The main index is **GAISI-beta**:

```text
GAISI_beta = (E1 + 0.5 × E2) / N
```

where:
- `E1` = weighted sum of E1 probabilities across tasks in the occupation
- `E2` = weighted sum of E2+E3 probabilities
- `N` = sum of task weights (normalisation)
- The 0.5 discount on E2 reflects that integrated exposure (E2) requires complementary software, making the net productivity effect smaller than direct use

Two alternative specifications are also available:

| Index | Formula | Interpretation |
|-------|---------|---------------|
| `gaisi_alpha` | E1 / N | Only direct LLM use; conservative lower bound |
| `gaisi_gamma` | (E1 + E2) / N | Full exposure; no E2 discount; upper bound |
| `hi_gaisi` | (P(E1>0.5) + 0.5 × P(E2>0.5)) / N | Threshold version: task counts only if majority-exposed |

---

## 3. Task Weighting

Task weights differ by measure:

### SES-based GAISI
Tasks are weighted by the **SES task importance score** — how important each task is to a specific job as reported by workers responding to the UK Skills and Employment Surveys 2017 and 2024. This is an individual-level weight (how central this task is to *this worker's* job), allowing the measure to vary within occupations as well as between them.

Individual-level GAISI is then averaged within occupation cells to produce occupation means.

### SSC-based GAISI
Tasks are weighted by **task relatedness** from the SSC task-occupation mapping (`sugs_task_description.xlsx`). Unlike SES, the SSC-based measures reflect *institutionally* defined task content — what occupations are normatively expected to involve, derived from expert descriptions, occupational standards, and employer demand signals:

```stata
taskweight = taskrelatedness / 100
```

`taskrelatedness` captures how central each SSC task is to the unit group. This is a fixed occupation-level weight, so all workers in a given SOC code receive the same GAISI.

---

## 4. Two Variants and Their Inputs

| | SES-based GAIEI | SSC-based GAISI |
|---|---|---|
| **Task framework** | SES tasks (Skills and Employment Survey) | SSC unit group tasks (~1,030 tasks across 330+ unit groups) |
| **Exposure ratings** | Multi-LLM: Gemini 1.5 Pro (×5), GPT-4o (×5) | Gemini 2.5 Pro with critic + adjudicator review |
| **Task weights** | SES task importance (individual-level) | SSC task relatedness score (occupation-level) |
| **Coverage** | UK occupations present in SES 2017 and 2023/24 | All SOC 2020 unit groups via SSC |
| **Raw data required** | SES microdata (proprietary) | SSC task descriptions (open) |
| **Output** | 2/3/4-digit SOC 2020; 3/4-digit SOC 2010 | 3/4-digit SOC 2020; 4-digit SOC 2010 |

---

## 5. SOC 2010 Conversion

Outputs are also provided in SOC 2010 to allow linkage with pre-2021 UK survey data (e.g. the Labour Force Survey before the SOC 2020 transition). The SOC 2020 → SOC 2010 conversion uses the ONS employment-share crosswalk:

```stata
merge m:m soc20m using "soc20_to_soc10_crosswalk.dta"
foreach var of varlist taskweight final_e? { replace `var' = `var' * emp_share_rescaled }
```

For 4-digit SOC 2010 cells with fewer than 5 task observations, the index falls back to the 3-digit cell average to reduce noise.

---

## 6. The Eloundou et al. Root Framework

The `eloundou_onet_to_uk_soc/` folder provides a separate set of indices derived directly from Eloundou et al. (2024) rather than from new LLM classifications. These use the same E0–E3 framework but apply the original GPT-4 and human rater scores from the US O\*NET task database, bridged to UK occupations via the SSC–O\*NET mapping. They are provided as an independent validation benchmark.

| Output | Source ratings | Formula |
|--------|---------------|---------|
| `gaisi_gpt` | GPT-4 classifications (Eloundou) | (gpt_E1 + 0.5×gpt_E2) / N |
| `gaisi_human` | Human rater aggregate (Eloundou) | (human_E1 + 0.5×human_E2) / N |
| `alpha` | Human rater (Eloundou) | Share of tasks with any exposure |
| `beta` | Human rater (Eloundou) | E1 + 0.5×E2 share |
| `gamma` | Human rater (Eloundou) | E1 + E2 share |

---

## 7. Key References

> Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2024). GPTs are GPTs: An early look at the labor market impact potential of large language models. *Science*, 384(6702), 1306–1308.
>
> Henseke, G., Davies, R., Felstead, A., Gallie, D., Green, F., & Zhou, Y. (2025). How Exposed Are UK Jobs to Generative AI? Developing and Applying a Novel Task-Based Index. *Working Paper.* [https://arxiv.org/abs/2507.22748](https://arxiv.org/abs/2507.22748)
