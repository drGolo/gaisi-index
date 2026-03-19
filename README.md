# UK GenAI Task Exposure Measures
 
This repository contains occupation-level and task-level measures of generative AI exposure for the UK labour market. All measures are constructed at the task level and aggregated to UK Standard Occupational Classification (SOC) codes.
 
## Structure
 
```
gaisi-index/
├── eloundou_onet_to_uk_soc/     Eloundou et al. (2024) mapped to UK SOC
├── gaisi_ses_based/              GAISI: SES task-weighted, LLM-classified
└── gaisi_ssc_based/              GAISI: SSC task-based, Gemini 2.5 Pro-classified
```
 
---
 
## 1. `eloundou_onet_to_uk_soc/` — Root Exposure Framework
 
Maps the task-level GenAI exposure scores from Eloundou et al. (2024) — "GPTs are GPTs" — to UK occupational classifications using the Standard Skills Classification (SSC) as a bridge between O\*NET tasks and UK SOC codes.
 
**Outputs:** Alpha, beta, gamma, and human-rater exposure indices at 4-digit and 3-digit SOC 2020 and SOC 2010.
 
---
 
## 2. `gaisi_ses_based/` — GAISI: Skills and Employment Survey (SES) Based
 
Constructs the **Generative AI Susceptibility Index (GAISI)** using task-level LLM exposure classifications weighted by task importance scores from the UK Skills and Employment Survey (SES 2017, 2024). Uses Gemini 1.5 Pro and GPT-4o for independent multi-run classification with probabilistic exposure estimates (E0/E1/E2/E3).
 
**Outputs:** Task-level exposure probabilities; GAISI indices at 2/3/4-digit SOC 2020 and SOC 2010.
 
---
 
## 3. `gaisi_ssc_based/` — GAISI: Standard Skills Classification (SSC) Based
 
Constructs the GAISI using the UK SSC task framework. SSC unit group tasks are classified by Gemini 2.5 Pro with a three-stage pipeline (classification → critic review → adjudication). Unlike the SES-based measure, this uses the SSC task descriptions ([UK Standard Skills Classification](https://www.gov.uk/government/publications/uk-standard-skills-classification-interim-development-report/the-uk-standard-skills-classification)).
 
**Outputs:** Task-level E0/E1/E2/E3 probabilities for ~40,300 sub-unit group–task combinations.
 
---
 
## Key Design Choices
 
- **Exposure levels** follow Eloundou et al. (2024): E0 = no exposure, E1 = direct LLM use, E2 = LLM integrated into tools, E3 = image-based LLM capability
- **Index construction**: `GAISI = E1 + 0.5 × E2` (main specification); variants use E1 only or E1 + E2
- **SOC crosswalks**: SOC 2020 → SOC 2010 conversion included for compatibility with pre-2021 survey data
 
See sub-folder READMEs for variable descriptions and file-level documentation.
 
---
 
## Licence
 
- **Data and indices**: Licensed under the [MIT License](LICENSE). You are free to use, modify, and redistribute with attribution.
- **Code** (Stata and Python scripts): Licensed under the [MIT License](LICENSE).
 
If you adapt or redistribute these measures, please retain the original attribution and licence notice.
 
---
 
## Citation
 
If you use these measures, please cite:
 
> Henseke, G., Davies, R., Felstead, A., Gallie, D., Green, F., & Zhou, Y. (2025). How Exposed Are UK Jobs to Generative AI? Developing and Applying a Novel Task-Based Index. *Working Paper.* [https://arxiv.org/abs/2507.22748](https://arxiv.org/abs/2507.22748)
 
> Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2024). GPTs are GPTs: An early look at the labor market impact potential of large language models. *Science*, 384(6702), 1306–1308.
 
---
 
## Contact
 
**Golo Henseke**
Associate Professor, UCL Institute of Education
[g.henseke@ucl.ac.uk](mailto:g.henseke@ucl.ac.uk) · [ORCID 0000-0003-0669-2100](https://orcid.org/0000-0003-0669-2100)
