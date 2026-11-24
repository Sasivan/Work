# Retest Rubric

**20 questions × 10 marks = 200 marks.** Use the same five-band style described in the original Python assessment package.

| Score | Band | General standard |
|---:|---|---|
| 10 | Excellent | Complete, correct, readable, and follows all explicit constraints including edge cases. |
| 7 | Good | Main behavior is correct; one limited omission or minor edge-case weakness. |
| 5 | Partial | Meaningful attempt but a core requirement, output, or robustness condition is incomplete. |
| 2 | Poor | Major implementation error or only limited understanding demonstrated. |
| 0 | Blank | No meaningful attempt. |

## Concept coverage

| Q | Concept | Max |
|---:|---|---:|
| 1 | Normalized-key, first-seen deduplication | 10 |
| 2 | Abstract base classes and interfaces | 10 |
| 3 | `map()` and lambda | 10 |
| 4 | Generator and incremental aggregation | 10 |
| 5 | Regex parsing of structured audit logs | 10 |
| 6 | Repeating-key encoding and alphabet wraparound | 10 |
| 7 | String normalization and numeric sanitization | 10 |
| 8 | Specific exceptions and logging | 10 |
| 9 | TDD and unit tests | 10 |
| 10 | Pandas dtype coercion | 10 |
| 11 | Grouped percentage aggregation | 10 |
| 12 | Exact category normalization and crosstab | 10 |
| 13 | Multi-sheet Excel union | 10 |
| 14 | Merge, derived measure and aggregation | 10 |
| 15 | Config-driven MySQL connection and logging | 10 |
| 16 | Raw extraction and source preservation | 10 |
| 17 | Data cleaning and rejection counts | 10 |
| 18 | Lookup enrichment | 10 |
| 19 | Idempotent load and round-trip validation | 10 |
| 20 | ETL refactor and written design reasoning | 10 |

## Important deductions

- Q4: loading all rows into a list defeats the generator/memory requirement.
- Q5: splitting the entire SQL statement on commas instead of splitting the captured column list breaks multi-column parsing.
- Q6: omitting modulo wraparound fails the written specification.
- Q7: returning `0` or raising for a code with no digits fails the `None` requirement.
- Q8: a bare `except`, `print`, or silently swallowed failure fails the logging/exception requirement.
- Q9: tests must include both valid and invalid boundary cases; booleans must be rejected.
- Q10: replacing an entire numeric column with a fixed value when one sentinel appears is incorrect; use coercion to missing values.
- Q11/Q12: report percentages at the requested group level; a proportion is not a percentage until multiplied by 100.
- Q12: do not use substring matching where exact category matching is specified; ambiguous/multi-value values go to `OTHER`.
- Q13: hardcoding sheet names/count or exporting only headers fails the all-sheet requirement.
- Q14: do not aggregate before joining in a way that duplicates service-catalog rows; verify lookup key uniqueness.
- Q15: credentials must come from configuration; logger must write to both console and file; re-raise failed connections.
- Q16: do not clean or drop malformed rows during extraction.
- Q17: report retained and rejected counts separately, and do not mutate the original raw structures.
- Q18: preserve clients during enrichment and explicitly detect missing lookup rows.
- Q19: a query string alone is not a load; execute it, make reruns safe, read the destination back, and compare actual values.
- Q20: stages must pass their outputs to the next stage; defining functions without a working orchestrator is incomplete.
