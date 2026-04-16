# NYU_QMBA_Final
Final group project for Quant. Methods for Business Analysis at NYU

## Data Cleaning requirements (Due Sunday night)

- Cumulative must be greater than monthly average
- Car value > $1000
- Ensure numeric fields are numeric (not text)
- Remove NULLs in critical fields
- Convert yes/no to 1/0
- Convert currency to numeric
- Education years < Age
- Employment years <= Age - 14
- Fix column naming error ("umber Pets" → "Number_Pets")
- Validate cumulative spend for Products A, B, and C: cumulative >= monthly
- Remove duplicate customer records based on unique identifier
- Employment and education years cannot be negative
- Income must be >= 0
- Use consistent capitalization
- No leading/trailing spaces

Masking technique and per-row reasons
------------------------------------
We build a boolean mask (`invalid_mask`) to mark rows failing any check, accumulating conditions with `|=`. In addition, we keep a parallel Series of lists called `invalid_reasons` that records one or more human-readable reasons for why a row was marked invalid.

Why both? The boolean mask is efficient for selecting rows, while `invalid_reasons` provides explainability (useful for debugging, audits, or reporting). We create `invalid_reasons` as a `pd.Series` where each element is a list; when a condition matches, we append a reason string to that row's list.

Example pattern (simplified):

```python
# start with all False (all rows valid)
invalid_mask = pd.Series(False, index=df.index)
# a Series of lists, one per row
invalid_reasons = pd.Series([[] for _ in range(len(df))], index=df.index)

# when a condition 'cond' is True for some rows, OR it into the mask
cond = df[['Age','Household_Income']].isna().any(axis=1)
invalid_mask |= cond

# append a reason string to the list for each matching row
# the `.loc[cond].apply(lambda lst: lst + ['Missing critical field'])` pattern
# takes the existing list and returns a new list with the reason appended
invalid_reasons.loc[cond] = invalid_reasons.loc[cond].apply(lambda lst: lst + ['Missing critical field'])

# After all checks, build invalid_df and cleaned_df
invalid_df = df[invalid_mask].copy()
# join the per-row lists into a single string column for reporting
invalid_df['Invalid_Reasons'] = invalid_reasons[invalid_mask].apply(lambda lst: '; '.join(lst) if lst else '')
cleaned_df = df[~invalid_mask].copy()
```

Notes and caveats:
- `invalid_reasons` stores lists; using `.loc[cond].apply(...)` returns new lists which are assigned back into those rows. This avoids mutating lists in-place and keeps behavior predictable.
- Ensure `cond` is a boolean Series aligned to `df.index`; use `cond.fillna(False)` if needed to avoid NA propagation.
- For readability and maintainability prefer a small helper (e.g. `mark(cond, reason)`) that abstracts the `|=` and `.loc[cond].apply(...)` steps — this is the pattern used in `dataclean.ipynb`.
- Finally, joining the list into a string (e.g. `'; '.join(...)`) makes the reasons easy to inspect in CSVs or reports.


# Questions about our customer base

do big household have a lot of pets?
do high income households prefer amex?
