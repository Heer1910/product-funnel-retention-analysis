# Product Funnel & Retention Analysis

Production-quality analytics project demonstrating funnel conversion and cohort retention analysis using GA4 BigQuery e-commerce data.

**Author:** Heer Patel  
**Project Type:** Product Analytics | Portfolio Project  
**Dataset:** Google GA4 BigQuery E-commerce Demo (Public Dataset)

---

## Project Overview

This project analyzes where users drop off in the e-commerce product lifecycle and why early retention is weak. Using event-level GA4 data, the analysis:

* Builds an ordered user-level funnel (view → add → checkout → purchase)
* Measures weekly cohort retention
* Calculates Day-1, Day-7, and Day-30 retention metrics
* Segments findings by device category

**Key Outputs:**
* Production-grade SQL queries with defensible metric definitions
* Reproducible Jupyter notebook analysis
* Publication-ready visualizations
* Executive summary with actionable recommendations

This project demonstrates analytics work as performed in mature product organizations: **clear metrics, defensible logic, and evidence-backed decisions**.

---

## Business Problem

The product shows:
* Strong top-of-funnel discovery
* Weak activation and early retention

**Stakeholder Questions:**
1. Where do users drop off in the funnel?
2. Is churn an early or late lifecycle problem?
3. Which user segments should be prioritized?
4. What experiment should be run next?

---

## Metric Definitions

### Funnel Stages

| Stage | Event | Definition |
|-------|-------|------------|
| **Product View** | `view_item` | First product view per user |
| **Add to Cart** | `add_to_cart` | First add-to-cart after view |
| **Begin Checkout** | `begin_checkout` | First checkout after add |
| **Purchase** | `purchase` | First purchase after checkout |

**Business Rules:**
* User-level grain (not event-level)
* Strict temporal ordering enforced
* 30-day window from first product view
* No double counting

**Conversion Rate Calculation:**
```
Stage-to-Stage Rate = Users(Stage N+1) / Users(Stage N)
Overall Conversion = Users(Purchase) / Users(View)
```

### Retention

**Cohort Anchor:** First `view_item` date  
**Active Definition:** ≥1 meaningful commerce event in a time period  
**Primary Cadence:** Weekly  
**Secondary Metrics:** D1, D7, D30

**Retention Calculation:**
```
Retention(cohort, period_n) = Active_Users(period_n) / Cohort_Size
```

---

## Dataset

**Source:** Google GA4 BigQuery E-commerce Demo  
**Access:** Public dataset, no authentication required beyond BigQuery setup  
**Path:** `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

**Sample Period:** January 2021 (configurable in SQL queries)

**Known Limitations:**
* Obfuscated values
* Incomplete event coverage
* Sampling may affect small segments

**Mitigations:**
* Explicit null handling in all queries
* Minimum cohort size filters (≥100 users)
* Conservative interpretation of findings

---

## Project Structure

```
product-funnel-retention/
├── sql/
│   ├── base_events.sql               # Event extraction and cleaning
│   ├── funnel.sql                    # User-level ordered funnel
│   ├── retention_weekly.sql          # Weekly cohort retention
│   └── retention_day_n.sql           # D1/D7/D30 retention metrics
├── notebooks/
│   └── analysis.ipynb                # Data extraction, analysis, visualization
├── figures/
│   ├── funnel_conversion.png         # Stage-to-stage conversion by device
│   ├── retention_heatmap.png         # Weekly cohort retention matrix
│   └── retention_curves.png          # Day-N retention decay curves
├── README.md                          # This file
├── executive_summary.md               # Findings and recommendations
└── requirements.txt                   # Python dependencies
```

---

## Usage

### Running the Analysis

1. **Start Jupyter:**
```bash
jupyter notebook
```

2. **Open notebook:**
* Navigate to `notebooks/analysis.ipynb`
* Run cells sequentially from top to bottom

3. **Expected outputs:**
* Funnel conversion metrics by device
* Weekly retention cohort table
* Day-N retention rates
* Three publication-ready charts in `figures/`

### Customizing the Analysis

**Change date range:**
* Edit `_TABLE_SUFFIX` filter in SQL queries
* Example: `BETWEEN '20210101' AND '20210331'` for Q1 2021

**Adjust cohort size threshold:**
* Modify `cohort_size >= 100` filter in retention queries
* Lower for more granularity, raise for statistical reliability

**Add device filters:**
* Modify `WHERE` clauses to focus on specific devices
* Example: `AND device.category = 'mobile'`

---

## Key Design Decisions

### 1. User-Level Grain for Funnel

**Decision:** Use first occurrence of each event per user.

**Rationale:**
* Funnel represents user progression, not all events
* Prevents double-counting and inflated conversion rates
* Aligns with standard product analytics practice

**Alternative:** Event-level analysis would overcount active users.

### 2. Strict Event Ordering

**Decision:** Enforce temporal ordering (add must follow view, etc.)

**Rationale:**
* Ensures funnel represents actual user journey
* Removes noise from out-of-order events (e.g., cached views)
* Makes results defensible in stakeholder discussions

**Trade-off:** May undercount conversions if event logging is unreliable.

### 3. 30-Day Funnel Window

**Decision:** All events must occur within 30 days of first view.

**Rationale:**
* E-commerce purchase decisions are typically short-term
* Prevents attribution of unrelated future purchases
* Industry standard for e-commerce funnels

**Alternative:** Could use session-based window, but loses multi-session journeys.

### 4. Behavioral Retention Definition

**Decision:** Define "active" as ≥1 commerce event in period.

**Rationale:**
* Meaningful engagement signal for e-commerce
* Avoids counting passive events (e.g., session starts)
* Actionable metric for product interventions

**Alternative:** Could use purchase-only, but misses engaged non-purchasers.

### 5. Device Category Segmentation

**Decision:** Segment all metrics by device (desktop, mobile, tablet).

**Rationale:**
* Device impacts both UX and conversion
* Enables prioritization of product investments
* Common segmentation in GA4 data

**Limitation:** GA4 "unknown" category may hide meaningful signals.

---

## Known Limitations

1. **Obfuscated Data:** GA4 demo dataset has anonymized values, limiting real-world applicability
2. **Sample Bias:** Public dataset may not represent full user population
3. **Event Coverage:** Not all user actions are captured as events
4. **Device Classification:** "Unknown" category may be substantial
5. **Observational Data:** Cannot make causal claims, only correlational

**Implications for Analysis:**
* Findings are directional, not absolute
* Focus on relative comparisons (device A vs. B) rather than absolute rates
* Recommendations should be validated with A/B tests

---

## Technologies Used

* **SQL:** BigQuery Standard SQL
* **Python:** 3.9+
* **Libraries:** pandas, matplotlib, seaborn, google-cloud-bigquery
* **Notebook:** Jupyter
* **Data Source:** Google GA4 Public Dataset

---

## Contact

**Heer Patel**  
[[My LinkedIn](https://www.linkedin.com/in/heerpatel19/)] | [[My GitHub](https://heer1910.github.io)] | [[My email](heerpatel7016@gmail.com)]

---

## License

This project is for portfolio and educational purposes. The GA4 public dataset is provided by Google under their terms of service.

---

## Acknowledgments

* Google Cloud for providing public GA4 dataset
* BigQuery documentation and SQL best practices
* Product analytics literature (Mixpanel, Amplitude guides)
