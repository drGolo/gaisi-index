# UK GenAI Task Exposure Measures

This repository contains occupation-level and task-level measures of generative AI exposure for the UK labour market. All measures are constructed at the task level and aggregated to UK Standard Occupational Classification (SOC) codes.

## Structure

```
uk_genai_task_exposure/
├── eloundou_onet_to_uk_soc/     Root framework: Eloundou et al. (2024) mapped to UK SOC
├── gaisi_ses_based/             GAISI: SES task-weighted, LLM-classified
└── gaisi_ssc_based/             GAISI: SSC task-based, Gemini 2.5 Pro-classified
```

---

## 1. `eloundou_onet_to_uk_soc/` — Root Exposure Framework

Maps the task-level GenAI exposure scores from Eloundou et al. (2024) — "GPTs are GPTs" — to UK occupational classifications using the Standard Skills Classification (SSC) as a bridge between O\*NET tasks and UK SOC codes. This is the foundational framework on which the SSC-based GAISI builds.

**Outputs:** Alpha, beta, gamma, and human-rater exposure indices at 4-digit and 3-digit SOC 2020 and SOC 2010.

---

## 2. `gaisi_ses_based/` — GAISI: Skills and Employment Survey (SES) Based

Constructs the **Generative AI Susceptibility Index (GAISI)** using task-level LLM exposure classifications weighted by task importance scores from the UK Skills and Employment Survey (SES 2017, 2024). Uses Gemini 1.5 Pro and GPT-4o for independent multi-run classification with probabilistic exposure estimates (E0/E1/E2/E3).

**Outputs:** Task-level exposure probabilities; GAISI indices at 2/3/4-digit SOC 2020 and SOC 2010.

---

## 3. `gaiei_ssc_based/` — GAISI: Standard Skills Classification (SSC) Based

Constructs the GAISI using the UK SSC task framework. SSC unit group tasks are classified by Gemini 2.5 Pro with a three-stage pipeline (classification → critic review → adjudication). Unlike the SES-based measure, this uses the SSC task descriptions [https://www.gov.uk/government/publications/uk-standard-skills-classification-interim-development-report/the-uk-standard-skills-classification](https://www.gov.uk/government/publications/uk-standard-skills-classification-interim-development-report/the-uk-standard-skills-classification).

**Outputs:** Task-level E0/E1/E2/E3 probabilities for ~40,300 sub-unit group-job task combinations.

---

## Key Design Choices

- **Exposure levels** follow Eloundou et al. (2024): E0 = no exposure, E1 = direct LLM use, E2 = LLM integrated into tools, E3 = image-based LLM capability
- **Index construction**: `GAISI = E1 + 0.5 × E2` (main specification); variants use E1 only or E1 + E2
- **SOC crosswalks**: SOC 2020 → SOC 2010 conversion included for compatibility with pre-2021 survey data

## Citation

If you use these measures, please cite:

> Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2024). GPTs are GPTs: An early look at the labor market impact potential of large language models. *Science*, 384(6702), 1306–1308.
> Henseke, G., Davies, R., Felstead, A., Gallie, D., Green, F., & Zhou, Y. (2025). How Exposed Are UK Jobs to Generative AI? Developing and Applying a Novel Task-Based Index. *Working Paper.* [https://arxiv.org/abs/2507.22748](https://arxiv.org/abs/2507.22748)
