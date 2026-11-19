# Observability Lab: MELT Telemetry Data Triage & Framework Analysis

## 1. Incident Overview & Operational Scope

The production checkout service experienced increased response latency and HTTP 500 failures. Distributed tracing shows that checkout requests stalled while waiting for a connection from `CheckoutDB-Pool`. The affected request spent approximately five seconds acquiring a database connection before failing with `SQLTransientConnectionException`. The database pool had 74 waiting threads, indicating connection-pool exhaustion. The incident affected checkout processing, including the promotional-voucher path, and prevented some customers from completing transactions.

---

## 2. MELT Telemetry Classification Matrix

| Signal Description | MELT Classification | Primary Data Format / Structure | Key Characteristics | Storage & Retention Trade-off |
|---|---|---|---|---|
| HTTP 500 error rate percentage over time | Metric | Numeric time series with timestamp and labels | Aggregated, low-context, broad service visibility | Low cost; retain for long-term trending and alerting |
| Deployment rollout completed notification (`v2.4.1`) | Event | Timestamped structured event with deployment metadata | Records a discrete system change and provides correlation context | Medium cost; retain through the deployment and audit window |
| Distributed request span waterfall (`/api/v1/checkout`) | Trace | Trace ID with parent-child spans, durations, status, and tags | High-cardinality request context across services | High cost; use sampling and shorter retention |
| Stack trace: `SQLTransientConnectionException` | Log | Timestamped structured or text log with exception and stack trace | Detailed code-level context for diagnosis | Medium to high cost; index important fields and apply limited retention |
| P99 response latency time series | Metric | Numeric time series in milliseconds | Aggregated percentile showing tail latency across requests | Low cost; suitable for dashboards, SLOs, and long retention |
| Kubernetes Horizontal Pod Autoscaler scaling from 5 to 10 replicas | Event | Timestamped Kubernetes event with old and new replica counts | Records an infrastructure state change | Medium cost; retain for incident correlation and audit |
| HikariCP connection acquisition latency warning message | Log | Timestamped application log with pool name, wait time, and message | Detailed diagnostic context about pool pressure | Medium cost; retain during operational investigation windows |
| Database connection-pool active connection count (50/50) | Metric | Gauge time series with pool and service labels | Aggregated resource-saturation measurement | Low cost; retain for capacity planning and alerting |
| Parent-child span hierarchy linking Gateway, Checkout, and DB | Trace | Distributed trace graph containing span and parent-span IDs | Shows request flow and isolates the slow downstream dependency | High cost; sample traces and retain errors longer than successful requests |
| Prometheus alert rule firing (`CheckoutServiceHighLatencyP99`) | Event | Timestamped alert event with rule name, labels, and state | Discrete notification generated when a metric threshold is exceeded | Medium cost; retain for incident history and alert-quality review |

---

## 3. Telemetry Source Selection & Incident Triage Strategy

### Recommended Triage Sequence

1. **Stage 1: Detection & Broad Impact Assessment**
   - **Pillar:** Metrics
   - **Rationale:** Begin with P99 latency, HTTP 500 error rate, CPU usage, replica count, and database-pool utilization. Metrics quickly establish when degradation began, its severity, and whether the impact is service-wide.

2. **Stage 2: Correlating System & Infrastructure Changes**
   - **Pillar:** Events
   - **Rationale:** Compare the metric degradation with deployment and Kubernetes events. The deployment of `v2.4.1` is the primary change to correlate with the start of the outage. The later HPA scale-out indicates a response to load or latency, not necessarily the cause.

3. **Stage 3: Isolating the Failing Component & Bottleneck Span**
   - **Pillar:** Traces
   - **Rationale:** Follow the `/api/v1/checkout` trace across the gateway, checkout service, promotional-voucher operation, and database. The trace isolates `HikariCP.acquireConnection` in `postgres-checkout-db` as the downstream bottleneck.

4. **Stage 4: Identifying Code Defect & Stack Trace**
   - **Pillar:** Logs
   - **Rationale:** Use application logs to identify the exact exception, source location, and connection-handling defect. Logs explain why the pool became exhausted and provide the code-level evidence required for remediation.

---

## 4. Checkout Incident Data Analysis & Root Cause Diagnosis

### A. Metric & Event Correlation

1. **When did the P99 latency and HTTP 500 error rate start degrading?**
   - **Observed Timestamp:** At the incident onset immediately after the `v2.4.1` rollout recorded in the telemetry snapshot.
   - **Pre-incident P99 vs Peak P99:** The P99 latency increased from its normal baseline to multi-second latency, with the failing request path spending approximately 5 seconds waiting for a database connection.
   - **Pre-incident Error Rate vs Peak Error Rate:** The HTTP 500 rate rose from its normal low baseline to an incident-level peak as database connection requests timed out.

2. **What specific deployment event correlates with the onset of the outage?**
   - **Event ID & Timestamp:** Deployment rollout-completed event at the start of the incident window.
   - **Target Image / Version Deployed:** `v2.4.1`
   - **Git Commit & Feature Summary:** The release introduced or changed the promotional-voucher/loyalty-discount checkout path. The failing trace executes `LoyaltyDiscountService.applyPromotionalVoucher` with voucher code `SUMMER_SALE`.

3. **Why did the automated scaling event fail to resolve the outage?**
   - **Explanation:** The HPA increased checkout pods from 5 to 10, but the bottleneck was the shared database connection pool rather than CPU capacity. The pool was saturated, with 50 of 50 active connections and 74 waiting threads. Adding application pods created additional demand for the same constrained database connections, so scaling could not clear the connection timeout condition.

### B. Distributed Trace & Log Root Cause Isolation

1. **Which span consumed 96%+ of the total request duration?**
   - **Span ID & Operation Name:** `span-006` — `HikariCP.acquireConnection`
   - **Span Duration vs Total Duration:** `5002 ms`; this accounts for nearly all of the failing checkout request's approximately 5.1-second duration.
   - **Failing Downstream Component:** `postgres-checkout-db`, using `CheckoutDB-Pool`

2. **What exception was thrown and what was the underlying code defect?**
   - **Exception Class:** `SQLTransientConnectionException`
   - **Root Cause Message:** `Connection is not available, request timed out after 5000ms`
   - **Originating Source File & Line Number:** The exact source file and line number must be copied from the application-log entry in `telemetry_incident_snapshot.json`; this value was not visible in the supplied terminal screenshot.
   - **Defect Explanation:** The deployed promotional-voucher path failed to release database connections reliably, causing a connection leak. As requests accumulated, `CheckoutDB-Pool` reached its 50/50 active-connection limit. Subsequent requests waited for a connection, producing 74 waiting threads and eventually timing out after 5000 ms.

---

## 5. Summary & Operational Telemetry Best Practices

1. Correlate metrics with deployment events. P99 latency and HTTP 500 alerts should be automatically overlaid with release and Kubernetes events so engineers can quickly identify changes that coincide with an outage.
2. Monitor the database pool directly. Alert on active/max connection ratio, pending threads, acquisition latency, timeout count, and leaked-connection warnings. A sustained pool usage above 80–90% should trigger investigation before the pool reaches 50/50 saturation.
3. Strengthen canary verification. Before promoting a new checkout release, run voucher and database-failure test cases, compare latency and error-rate SLOs against the previous version, and verify that database connections return to the pool after every request. Automatically roll back when canary error rate or P99 latency exceeds the approved threshold.
