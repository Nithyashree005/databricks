# Observability Lab: Datadog APM & Service Map Flow Investigation

## 1. Investigation Summary & Topology Context
<!-- Briefly summarize the Datadog incident, the service triggering the alert, and overall transaction flow. -->


---

## 2. Datadog Service Map Dependency Analysis

Complete the service map dependency table based on `datadog_apm_servicemap.json`:

| Service Name | Service Type / Engine | Throughput (RPM) | Error Rate (%) | Latency P95 (ms) | Status |
|---|---|---|---|---|---|
| `web-storefront` | | | | | |
| `checkout-service` | | | | | |
| `payment-api` | | | | | |
| `postgres-payment-db` | | | | | |
| `stripe-external-gateway` | | | | | |

### Service Map Dependency Traversal:
- **Upstream Callers of `payment-api`:**
- **Downstream Dependencies of `payment-api`:**
- **Propagation of Error Rates:** Explain how database errors in `postgres-payment-db` cascade upward through `payment-api` into `checkout-service`:

---

## 3. APM Trace & Flame Graph Breakdown

Analyze the APM flame graph trace (`trace_id: dd-88491029141`) to inspect span execution times:

| Span ID | Service Name | Resource / SQL Statement | Start (ms) | Duration (ms) | % of Trace Latency | Error Flag (0 / 1) |
|---|---|---|---|---|---|---|
| `span-dd-01` | | | | | | |
| `span-dd-02` | | | | | | |
| `span-dd-03` | | | | | | |
| `span-dd-04` | | | | | | |

---

## 4. Root Cause & Database Bottleneck Diagnosis

Answer the following diagnostic questions based on your findings:

1. **Which specific database query is responsible for 97%+ of the total request latency?**
   - *SQL Statement:*
   - *Duration (ms):*
   - *Error Type & Message:*

2. **Why is the database query blocking (refer to connection count and lock wait queue)?**
   - *PostgreSQL Connection Pool Status:*
   - *Row Lock Contention (`FOR UPDATE` clause impact):*

3. **Did the external Stripe payment gateway contribute to this outage? Cite its latency and error rate:**
   - *Stripe Latency:*
   - *Stripe Error Rate:*
   - *Conclusion:*

---

## 5. Architectural Remediation & Observability Recommendations
<!-- Provide 3 concrete engineering fixes (e.g., query optimization, non-blocking locks, connection pooling, Datadog monitor threshold alerts). -->
