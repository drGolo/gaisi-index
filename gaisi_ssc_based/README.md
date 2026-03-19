# GAISI — Standard Skills Classification (SSC) Based

The **Generative AI Exposure Index (GAISI)** constructed by classifying tasks from the UK Standard Skills Classification (SSC) using a three-stage classification pipeline (classify → critic → adjudicate), then aggregating to UK SOC codes using SSC task-occupation weights.

Unlike the SES-based GAISI, this measure does not rely on survey data. All task descriptions come from the SSC framework.

## Method

1. **Task classification**: Each SSC unit group task (~1,030 tasks) is classified by Gemini 2.5 Pro using the system prompt in `prompts/system_prompt_Dec2025.txt`. The model assigns probabilities over four exposure levels (E0/E1/E2/E3).

2. **Critic review**: A second Gemini pass reviews each classification against the task justification, identifying disagreements.

3. **Adjudication**: Flagged cases are reviewed by the adjudicator model using a dedicated system prompt, producing a final reconciled classification stored in `classification_results/gaisi_classifications_adjudicated.csv`.

4. **Aggregation to SOC**: `pipeline/proces_classification_outputs.do` weights task exposure scores by SSC task relatedness and collapses to 4-digit SOC 2020 and SOC 2010.

## Relation to Eloundou et al

The exposure level definitions (E0–E3) follow Eloundou et al. (2024) and are consistent across this measure and the `eloundou_onet_to_uk_soc/` folder. This measure provides a UK-native replication of the GPTs are GPTs framework using SSC tasks classified by an updated LLM (Gemini 2.5 Pro) rather than the original GPT-4 ratings applied to O\*NET tasks.

## Contents

```text
prompts/
  system_prompt_Dec2025.txt              Main Gemini classification system prompt
  system_prompt_adjucator_dec2025.txt    Adjudicator review prompt
  system_prompt_critic_dec2025.txt       Critic review prompt

ssc_tasks/
  SSC - Tasks - v0.9.1 - 20251124.xlsx  SSC task list with unit group codes and descriptions
  SSC - Mappings - ONET - v0.9.0 - 20251124.xlsx  SSC → O*NET task crosswalk
  sugs_task_description.xlsx            SUG-to-task mapping with task relatedness weights
  soc20_to_soc10_crosswalk.dta          ONS SOC 2020 → SOC 2010 employment-share crosswalk
  sug_codes_descriptions.csv            SUG codes and titles (LLM classification input)
  sugs_to_tasks.csv                     SUG-to-task mapping (LLM classification input)
  sug_1258_11.csv                       Full classification input batch

classification_results/
  gaisi_classifications_adjudicated.csv  Final adjudicated task classifications
                                          Columns: sugcode, taskid, taskstatement,
                                          e0/e1/e2 (LLM probs), critic_confidence,
                                          adjudicator_e0/e1/e2, adjudicator_verdict

pipeline/
  gaisi_ssc_classification.py           Gemini Batch API classification (Google Colab)
  gaisi_critic_review.py                Critic and adjudicator review script
  proces_classification_outputs.do      Stata: aggregate task scores → SOC 2020 + SOC 2010
 
output/
  ssc_task_level_genai_exposure_score.dta   Task-level weighted exposure scores
  ssc_task_level_genai_exposure_score.csv   As above, CSV
  soc2020_4digit_gaisi_ssc.dta              GAISI at 4-digit SOC 2020
  soc2020_4digit_gaisi_ssc.csv              As above, CSV
  soc2010_4digit_gaisi_ssc.dta              GAISI at 4-digit SOC 2010
  soc2010_4digit_gaisi_ssc.csv              As above, CSV

  task_level/                               Supplementary: AEI–SSC task matching files
    ssc_classification.dta                  Raw task-level E0/E1/E2 probabilities from Gemini
    aei_ssc_probabilistic_task_mapping.dta  Probabilistic SSC–Anthropic AEI task matching
    aei_ssc_probabilistic_task_mapping.csv  As above, CSV
    aei_ssc_matched_tasks_set1.dta
    aei_ssc_matched_tasks_set2.dta
    aei_ssc_task_name_mapping.dta
```

## Output Variables

### `ssc_task_level_genai_exposure_score`

Task-level output after applying task weights. Key variables:

| Variable | Description |
|----------|-------------|
| `sugcode` | SSC unit group code |
| `taskid` | SSC task ID |
| `final_e0/e1/e2` | Final exposure probabilities (adjudicated if available, else LLM) |
| `taskweight` | `taskrelatedness / 100` |
| `w_final_e1/e2` | Weighted exposure (`final_e* × taskweight`) |
| `hi_e1/e2` | Binary: 1 if probability > 0.5 |

### `soc2020_4digit_gaisi_ssc` / `soc2010_4digit_gaisi_ssc`

Occupation-level indices. Key variables:

| Variable | Formula | Description |
|----------|---------|-------------|
| `gaisi_beta` | (E1 + 0.5×E2) / N | Main index |
| `gaisi_alpha` | E1 / N | Conservative (direct exposure only) |
| `gaisi_gamma` | (E1 + E2) / N | Full exposure (no E2 discount) |
| `hi_gaisi` | (hi_E1 + 0.5×hi_E2) / N | Threshold version |
| `N` | Σ taskweight | Effective task weight denominator |

## Running the Pipeline

**Step 1 — LLM classification** (Google Colab):

1. Upload `ssc_tasks/sug_codes_descriptions.csv` and `ssc_tasks/sugs_to_tasks.csv` to `My Drive/AI_CLASSIFICATION/Inputs/`
2. Set `GOOGLE_API_KEY` in Colab secrets
3. Run `gaisi_ssc_classification.py` cell by cell — submits batch job, polls for results
4. Run `gaisi_critic_review.py` for the critic/adjudicator pass
5. Download results and save as `classification_results/gaisi_classifications_adjudicated.csv`

**Step 2 — Aggregation to SOC** (Stata):

1. Update the `cd` path at the top of `proces_classification_outputs.do`
2. Run the script — outputs saved to `output/`

## Citation

If you use these measures, please cite:

> Eloundou, T., Manning, S., Mishkin, P., & Rock, D. (2024). GPTs are GPTs: An early look at the labor market impact potential of large language models. *Science*, 384(6702), 1306–1308. [https://doi.org/10.1126/science.adj0998](https://doi.org/10.1126/science.adj0998)
>
> Henseke, G., Davies, R., Felstead, A., Gallie, D., Green, F., & Zhou, Y. (2025). How Exposed Are UK Jobs to Generative AI? Developing and Applying a Novel Task-Based Index. *Working Paper.* [https://arxiv.org/abs/2507.22748](https://arxiv.org/abs/2507.22748)
>
> Skills England. (2025). The UK Standard Skills Classification. [https://www.gov.uk/government/publications/uk-standard-skills-classification-interim-development-report/the-uk-standard-skills-classification](https://www.gov.uk/government/publications/uk-standard-skills-classification-interim-development-report/the-uk-standard-skills-classification)
