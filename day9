# Reading Telemetry & Observability - Instructor Solution Guide: Day 2 (Browser-Only Edition)

## 1. Classification of the Original Kit

| Scenario | Original local / CLI / Docker dependency | Platform work | Change |
| :--- | :--- | :--- | :--- |
| S1 TEL-D2-201 Dynatrace | `validation_script start/check`, local evidence file, systemd Java services | Dynatrace UI | Converted: worksheet + instructor sign-off |
| S2 TEL-D2-202 Datadog | Local scripts, Postgres deadlock setup | Datadog UI | Converted to Datadog only: monitor, APM, Logs |
| S3 TEL-D2-203 Grafana | Local scripts, **Docker Prometheus/Grafana**, `check_escalation.sh` | Grafana UI | Converted to Grafana only: shared Grafana + read-only Prometheus |

All learner-side CLI, Docker and localhost steps are removed. The old provider scripts (setup_*.sh, *_ctl.sh, app.py, configure_*.sh, create_monitors.sh, check_escalation.sh) are removed; their role is covered by the instructor-only runbook (Section 5) and the `validation_script` helpers in each `s*/` folder.

**Assumption to confirm:** scenario stories now use the shared easyTravel environment (fault `CreditCardCheckError500`). The old ShopNow story identifiers (P-24101, `TXN-88129-CORR`, `StripeGatewayConnector`, `pg_sleep`) are retired. Only the shared Grafana URL must be supplied by you (Splunk, Kibana and New Relic are no longer used in Day 2 scenarios).

## 2. Before Class (Instructor Only)

1. Share the three worksheet copies (`Evidence_D2_1/2/3`) per learner.
2. Confirm the shared Grafana URL (read-only Prometheus data source) and fill the placeholder in the Participant Guide.
3. Enable the fault `CreditCardCheckError500` at the announced start time and note the UTC time.
4. Confirm Davis has opened a problem, the Datadog composite monitor is in ALERT and Datadog APM/Logs show the failed traces.
5. Disable the fault when class ends; confirm problems close.

## 3. Answer Keys and Sign-Off Checks

### S1 TEL-D2-201 (Dynatrace)

| Rule | Instructor checks in browser | Expected answer |
| :--- | :--- | :--- |
| 1 Problem identified | Worksheet problem ID/title exists in Problems app | Davis problem on easyTravel, start time within the incident window |
| 2 Root cause isolated | Root cause entity named, not only affected ones | easyTravel payment / credit-card check service |
| 3 Code-level evidence | Failed request opened in PurePath | Exception/span mentioning `CreditCardCheckError500` |
| 4 Cross-check | Smartscape or Services screenshot | Flow frontend → backend → payment check |
| 5 Complete | No `<<FILL_...>>`, query path present | Next action named |

### S2 TEL-D2-202 (Datadog only)

| Rule | Instructor checks | Expected answer |
| :--- | :--- | :--- |
| 1 Alert identified | Monitor name, time, thresholds | Composite/`[SHARED]` error-rate monitor in ALERT |
| 2 Service isolated | Service tag | easyTravel backend (`env:cohort`) |
| 3 Log evidence | Pasted log row | Error with `CreditCardCheckError500` and the trace ID |
| 4 Second view | Trace ID matches in APM and Logs | IDs match |
| 5 Complete | Trace and Logs queries pasted | Verdict: monitor, trace and logs agree |

### S3 TEL-D2-203 (Grafana only)

| Rule | Instructor checks | Expected answer |
| :--- | :--- | :--- |
| 1 Window identified | Incident window on dashboard | Matches start time |
| 2 Hypothesis | One cause explains latency and errors | Failing credit-card check |
| 3 Evidence | Panel link has `viewPanel=`; PromQL with values | p95 rise and error ratio rise in the window |
| 4 Alert rule | Related rule and state read, not edited | State noted |
| 5 Escalation note | Severity, owner, ask, next update, 3-sentence summary | Owner from service catalog |

## 4. Validation Checklist per Learner (about 3 minutes)

- Open worksheet beside the platform.
- Tick each rule only after seeing it on screen; do not rely on screenshots alone, spot check one query live.
- Record result in the class tracker (seat, scenario, rules passed).
- Pass mark: 5 of 5 for sign-off; 4 of 5 = retry once.

## 5. Instructor-Only Runbook (Replaces Provider Scripts)

| Task | Where | Notes |
| :--- | :--- | :--- |
| Start fault | easyTravel config service on `ip-172-30-0-220` (`setPluginEnabled`, `CreditCardCheckError500`) | Instructor only; learners never run this |
| Stop fault | Same service | Do at class end |
| Grafana hosting | Pre-built shared instance | Viewer role; Prometheus read-only |
| Retire | Old Postgres deadlock, stress-ng and Docker scripts | No longer needed for learners |

Commands are intentionally not repeated in learner materials; keep credentials out of all guides.

## 6. Common Learner Mistakes

| Mistake | Fix |
| :--- | :--- |
| Naming affected service as root cause | Re-check Davis root cause entity |
| Logs query without time range | Set Past 2 Hours |
| Grafana link without `viewPanel=` | Use panel View then copy URL |
| Editing shared monitors/dashboards | Stop; read-only |
