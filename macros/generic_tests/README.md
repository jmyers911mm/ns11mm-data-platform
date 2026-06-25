# Generic Test Macros

Reusable schema test macros for the NS11MM data platform.

| Macro | Purpose |
|---|---|
| `test_hashdiff_integrity` | Validates no null hashes and no hash collisions across different keys |
| `test_referential_integrity` | Reusable FK validation between any parent/child models |
| `test_row_count_drift` | Alerts when row count hits zero or extreme deviation |
| `test_late_arriving_data` | Detects rows with business timestamp beyond max lag before load time |
| `test_schema_drift` | Compares model actual columns against an expected list |
| `null_rate_threshold` | Fails if column null percentage exceeds threshold (default 50%) |
| `daily_volume_bounds` | Validates daily row counts stay within min/max bounds |
| `cardinality_change` | Alerts if distinct value count falls outside expected range |
| `distribution_shift` | Detects when a specific value frequency drifts outside acceptable range |
| `z_score_outlier` | Flags rows where a numeric column exceeds N standard deviations (default 3) |
| `positive_value` | Fails if any row has a negative value in the specified column |
| `value_between` | Fails if any row's value is outside min/max bounds |

## Usage

```yaml
# schema.yml
models:
  - name: silver_pos_tickets
    columns:
      - name: hashdiff
        tests:
          - hashdiff_integrity:
              key_column: transaction_id
      - name: total_amount
        tests:
          - positive_value
          - value_between:
              min_value: 0
              max_value: 10000
          - z_score_outlier:
              max_zscore: 4
      - name: customer_email
        tests:
          - null_rate_threshold:
              threshold: 0.3
```
