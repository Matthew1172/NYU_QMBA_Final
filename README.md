# NYU_QMBA_Final
Final group project for Quant. Methods for Business Analysis at NYU
Data Cleaning requirements (Due Sunday night)
Cumulative has to be greater than monthly avg
Car value > $1000
Make sure numbers are stored as such and not text. 
Delete NULL
Make all 1, 0 not yes no
Currency to Number
Education years < Age
Employment years > Age - 14
Fix column naming error (“umber Pets” → “Number Pets”)
Validate cumulative spend for Products A, B, and C is greater than or equal to monthly spend; identified 2992 errors for Product A, 202 for Product B, and 174 for Product C(Ran this in RStudio to confirm)
Validate the car value is above a realistic threshold (1000); identified 50 entries below this threshold and treated them as invalid data. (RStudio check there)
Remove duplicate customer records based on unique identifier
Employment and education years cannot be negative.
Income must be greater than or equal to 0
Use consistent capitalization
No leading/ trailing spaces

Masking technique (boolean masks)
-------------------------------
When validating rows we build a boolean mask (`invalid_mask`) that marks rows failing any check. We accumulate failing conditions with the in-place-or operator `|=` which sets a row to True when any condition is met. After all checks are combined, we use the bitwise NOT operator `~` to invert the mask and select the valid rows.

Example:

```python
# start with all False (all rows valid)
invalid_mask = pd.Series(False, index=df.index)

# mark rows with missing critical fields as invalid
# use operator |= to accumulate all rows which fail this condition
invalid_mask |= df[['Age','Household_Income']].isna().any(axis=1)

# mark rows where cumulative < monthly as invalid
invalid_mask |= df['Cumulative_Spend_ProductA'] < df['Monthly_Spend_ProductA']

# invalid_df contains rows that failed any check
invalid_df = df[invalid_mask]

# cleaned_df contains the rows that passed all checks
cleaned_df = df[~invalid_mask]
```

Notes:
- `|=` accumulates (ORs) boolean conditions into the mask without overwriting prior checks.
- `~` inverts the boolean Series so it can be used to select rows that are not invalid.
- This approach keeps the validation logic declarative and makes it easy to save `invalid_df` and `cleaned_df` separately.

