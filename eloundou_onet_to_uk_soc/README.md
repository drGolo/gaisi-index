# Eloundou et al. (2024) GenAI Exposure — Mapped to UK SOC

Maps the task-level GenAI exposure scores from Eloundou et al. (2024) — "GPTs are GPTs" — to UK Standard Occupational Classification (SOC) codes, using the Standard Skills Classification (SSC) as a bridge between O\*NET tasks and UK SOC.

This is the root exposure framework. The GAISI measures in `gaisi_ses_based/` and `gaisi_ssc_based/` adopt the same E0–E3 exposure level definitions and GenAI exposure index formula.

## Method

Eloundou et al. classify O\*NET task statements into four exposure levels (E0–E3) using both human raters and GPT-4. These O\*NET tasks are matched to SSC unit group tasks via the SSC–O\*NET mapping file (`SSC - Mappings - ONET`). Task-level scores are weighted by SSC task similarity scores and aggregated to UK SOC occupations via the SOC 2020 unit group codes embedded in the SSC structure, then converted to SOC 2010 via an employment-share crosswalk.

## Contents

```text
source/
  full_labelset.tsv              Eloundou et al. task-level classifications (O*NET)
                                  Columns: taskid, task, human_exposure_agg, gpt4_exposure,
                                  alpha, beta, gamma, automation, human_labels

ssc_onet_bridge/
  SSC - Mappings - ONET - v0.9.0 - 20251124.xlsx   SSC task to O*NET task crosswalk (similarity scores)
  SSC - Tasks - v0.9.1 - 20251124.xlsx              SSC task definitions and unit group codes
  sugs_task_description.xlsx                        SSC task-relatedness weights by unit group
  soc20_to_soc10_crosswalk.dta                      ONS SOC 2020 to SOC 2010 employment-share crosswalk

pipeline/
  map_emmr_ratings_to_uk_soc.do   O*NET to SSC bridge to SOC 2020/2010

output/
  soc2020_4digit_gpts_are_gpts.dta/.csv   Eloundou human-rater and GPT-4 indices, 4-digit SOC 2020
  soc2010_4digit_gpts_are_gpts.dta/.csv   Eloundou human-rater index, 4-digit SOC 2010
```

## Output Variables

| Variable | Formula | Description |
|----------|---------|-------------|
| `emmr_gpt` | (gpt_E1 + 0.5×gpt_E2) / N | GPT-4 rated exposure index |
| `emmr_human` | (human_E1 + 0.5×human_E2) / N | Human rater exposure index |

Both indices follow the EMMR beta formula. N is total task-relatedness weight across matched SSC tasks for the occupation.

## Running the Pipeline

1. Update the `cd` path at the top of `map_emmr_ratings_to_uk_soc.do` for your machine
2. Ensure `ssc_onet_bridge/` files and `source/full_labelset.tsv` are present
3. Run the script to produce both output files

## Citation

`full_labelset.tsv` is redistributed from Eloundou et al. (2024) supplementary materials, cloned from [github.com/openai/GPTs-are-GPTs](https://github.com/openai/GPTs-are-GPTs). Please cite the original paper:

> Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2024). GPTs are GPTs: An early look at the labor market impact potential of large language models. *Science*, 384(6702), 1306–1308. [https://doi.org/10.1126/science.adj0998](https://doi.org/10.1126/science.adj0998)
