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
