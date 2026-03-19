# GAIEI — Skills and Employment Survey (SES) Based

The **Generative AI Exposure Index (GAIEI)** constructed using LLM-based task-level exposure classifications weighted by task importance scores from the UK Skills and Employment Survey (SES 2017 and 2023/24).

## Method

### Step 1 — LLM task classification

SES tasks are classified by two LLMs across multiple independent runs:

- **Gemini 1.5 Pro**: 5 runs (`job_task_probabilities_gemini_r1–r5.csv`)
- **GPT-4o**: 5 runs (`job_task_probabilities_gpt4o_batched_r1–r5.xlsx`)

Each run assigns a probability distribution over E0/E1/E2/E3 for each task–occupation cell. Probabilities are averaged across runs. Gemini 1.5 Pro is the primary model; GPT-4o ratings are used as backup.

### Step 2 — Merge with SES and weight by task importance

Task-level exposure probabilities are merged into the SES microdata and weighted by each respondent's task importance rating. This produces an **individual-level GAISI** for every SES respondent in 2017 and 2023/24.

```text
GAISI_beta = E1 + 0.5 × E2
```

where E1 and E2 are task-importance-weighted mean exposure probabilities for the individual.

### Step 3 — Aggregate to occupation

Individual GAISI scores are pooled across both SES waves and collapsed to **3-digit SOC** (2020 and 2010) using survey weights. Small cells (N < 6) are imputed from the 2-digit level via tobit regression.

The occupation-level outputs report:

| Variable | Description |
|----------|-------------|
| `hi_gaisi` | Share of workers above the 80th percentile of the GAISI distribution |
| `gaisi_rank` | Mean percentile rank (0–10 scale, population-weighted) |
| `p50_gaisi_rank` | Median percentile rank |
| `N` | Sum of survey weights (effective sample size) |

## Contents

```text
prompts/
  main_prompt.txt              System + user prompt used for classification (paper appendix version)
  classification_examples.txt  Few-shot examples provided to the LLM

classification_results/
  job_task_probabilities_gemini_r1–r5.csv    Gemini 1.5 Pro: 5 independent runs
  job_task_probabilities_gpt4o_batched_r1–r5.xlsx  GPT-4o: 5 independent runs

justification_coding/
  codebook.txt / codebook_final.txt          Coding scheme for LLM justifications
  justification_coding_system_prompt.txt     Prompt used to code justifications
  justification_codes.csv                    Full justification coding results
  justification_codes_final.dta              Stata-format final coding

pipeline/
  gemini_ses_ai_task_classification_probabilistic_Apr2025.py  Google Colab notebook: LLM classification runs
  process-gaisi_job_task_classification_ses.do                Step 1: average runs → task-level scores
  map-job_task_ratings_to_ses2024_2017.do                     Step 2: merge into SES, weight by importance
  create-occupation-average-gaisi-scores-ses.do               Step 3: collapse to occupation-level

output/
  job_task_level_exposure_scores.dta              Task-level averaged probabilities (steps 1→2 bridge)
  job_task_exposure_probabilities_gpt4o_gemini.csv  As above, CSV (long format)
  soc2020_3digit_gaisi_ses.dta                    Occupation-level GAISI, 3-digit SOC 2020
  soc2020_3digit_gaisi_ses.csv                    As above, CSV
  soc2010_3digit_gaisi_ses.dta                    Occupation-level GAISI, 3-digit SOC 2010
  soc2010_3digit_gaisi_ses.csv                    As above, CSV

  [NOT INCLUDED] ses2024_job_gaisi.dta            Individual-level GAISI, SES 2023/24 — derived
  [NOT INCLUDED] ses2017_job_gaisi.dta            from proprietary SES microdata (see Data Access)
```

## Data Access

The individual-level SES files (`ses2017_job_gaisi.dta`, `ses2024_job_gaisi.dta`) are derived from access limited survey microdata and are not included in this repository. To reproduce Steps 2 and 3, obtain the SES data from the UK Data Service:

> Felstead, A., Gallie, D., Green, F., Henseke, G. (2019). *Skills and Employment Surveys Series Dataset, 1986, 1992, 1997, 2001, 2006, 2012 and 2017.* [data collection]. UK Data Service. SN: 8589. DOI: [10.5255/UKDA-SN-8589-1](http://doi.org/10.5255/UKDA-SN-8589-1)

The SES 2023–24 update will be available on the UK Data Service from Q2 2026.

All output files derived at occupation level (`soc*_gaisi_ses.*`) and at task level (`job_task_level_exposure_scores.*`) are included and can be used without SES access.

## Running the Pipeline

All three scripts use the `gaiei_ses_based/` folder as their working directory. Update the `cd` and `$ses_2023` / `$ses_2017` globals at the top of each file for your machine. Steps 2 and 3 require the SES microdata (see Data Access above); Step 1 and all provided output files do not.

## Missing Content / Known Issues

- ⚠️ **4-digit SOC not produced**: Occupation outputs are 3-digit SOC only (both 2020 and 2010). Sample sizes at 4-digit level are too small for reliable estimates with SES data.

## Citation

The classification is discussed and validated in:

> Henseke, G., Davies, R., Felstead, A., Gallie, D., Green, F., & Zhou, Y. (2025). How Exposed Are UK Jobs to Generative AI? Developing and Applying a Novel Task-Based Index. *Working Paper.* [https://arxiv.org/abs/2507.22748](https://arxiv.org/abs/2507.22748)