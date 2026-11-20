# Observability Lab: Datadog APM & Service Map Flow Investigation

## Investigation Summary & Topology Context

The Datadog APM investigation identified elevated errors and latency in the payment\-api service in the production environment. The service showed a 14.2% error rate and critical latency. The transaction flow traverses web\-storefront → checkout\-service → payment\-api, with payment\-api communicating with both postgres\-payment\-db and stripe\-external\-gateway.

The primary bottleneck is the PostgreSQL database dependency. The database has 98 active connections out of a maximum of 100 and a lock wait queue of 34. A blocking SELECT ... FOR UPDATE query inside the payment trace consumed 5008 ms of the 5120 ms total request duration.

---

## Datadog Service Map Dependency Analysis

| Service Name | Service Type / Engine | Throughput (RPM) | Error Rate (%) | Latency P95 (ms) | Status |
| --- | --- | --- | --- | --- | --- |
| web\-storefront | Web / Node.js | 12000 | 3.8 | 520 | WARNING |
| checkout\-service | API / Java | 4500 | 9.4 | 2800 | DEGRADED |
| payment\-api | API / Python FastAPI | 1800 | 14.2 | 4850 | CRITICAL |
| postgres\-payment\-db | Database / PostgreSQL 15.3 | N/A | N/A | N/A | CRITICAL |
| stripe\-external\-gateway | Third\-party service | 1600 | 0.2 | 110 | HEALTHY |

### Service Map Dependency Traversal

**Upstream Callers of** **payment\-api****:**

checkout\-service is the direct upstream caller of payment\-api, generating 1800 calls per minute with a 14.2% error rate on this dependency. Further upstream, web\-storefront calls checkout\-service at 4500 RPM.

**Downstream Dependencies of** **payment\-api****:**

payment\-api has two downstream dependencies:

- postgres\-payment\-db: 3600 calls per minute with an 18.0% error rate.
- stripe\-external\-gateway: 1600 calls per minute with only a 0.2% error rate.

**Propagation of Error Rates:**

The primary failure originates in the critical postgres\-payment\-db dependency, where the payment\-api → postgres\-payment\-db edge has an 18.0% error rate. Database lock contention causes requests from payment\-api to block and eventually time out. This contributes to the 14.2% error rate at payment\-api. Because checkout\-service depends on payment\-api, these failures propagate upstream, contributing to its 9.4% error rate and degraded state. The impact continues toward web\-storefront, which is in WARNING state with a 3.8% error rate.

---

## APM Trace & Flame Graph Breakdown

Trace ID: dd\-88491029141

| Span ID | Service Name | Resource / SQL Statement | Start (ms) | Duration (ms) | % of Trace Latency | Error Flag (0 / 1) |
| --- | --- | --- | --- | --- | --- | --- |
| span\-dd\-01 | payment\-api | POST /api/v1/payments/process | 0 | 5120 | 100.00% | 1 |
| span\-dd\-02 | payment\-api | validate\_customer\_wallet | 5 | 25 | 0.49% | 0 |
| span\-dd\-03 | payment\-api | SELECT \* FROM payment\_accounts WHERE account\_id = ? FOR UPDATE | 32 | 5008 | 97.81% | 1 |
| span\-dd\-04 | payment\-api | stripe\_external\_authorize | 5045 | 70 | 1.37% | 0 |

The APM trace confirms that the PostgreSQL query dominates request execution time. span\-dd\-03 consumes approximately 97.81% of the 5120 ms trace duration and is the span where the database timeout occurs.

---

## Root Cause & Database Bottleneck Diagnosis

**Which specific database query is responsible for 97%\+ of the total request latency?**

- *SQL Statement:* SELECT \* FROM payment\_accounts WHERE account\_id = ? FOR UPDATE
- *Duration (ms):* 5008 ms, approximately 97.81% of the 5120 ms trace
- *Error Type & Message:* psycopg2.errors.QueryCanceled \- canceling statement due to statement timeout (5000ms)

The top\-level request ultimately fails with HTTP 500 and reports: QueryTimeout: Lock wait timeout exceeded; try restarting transaction.

**Why is the database query blocking (refer to connection count and lock wait queue)?**

- *PostgreSQL Connection Pool Status:* The database has 98 active connections out of a maximum of 100, representing 98% connection utilization. This leaves only two connections of available capacity. The lock wait queue contains 34 waiting requests.
- *Row Lock Contention (**FOR UPDATE* *clause impact):* The query uses FOR UPDATE, which obtains row\-level locks on the selected payment account records. Concurrent payment transactions attempting to lock the same records must wait for existing transactions to release those locks. Under high concurrency, this creates lock contention and a growing wait queue. In this trace, the wait ultimately reaches the configured 5000 ms statement timeout and the PostgreSQL query is canceled.

**Did the external Stripe payment gateway contribute to this outage? Cite its latency and error rate:**

- *Stripe Latency:* 110 ms P95 on the Service Map; the Stripe trace span completed in 70 ms.
- *Stripe Error Rate:* 0.2%
- *Conclusion:* No. stripe\-external\-gateway is HEALTHY, has a low 0.2% error rate, and its APM span completed successfully with error flag 0. The dominant latency and failure originate from the PostgreSQL query, not the external Stripe dependency.

---

## Architectural Remediation & Observability Recommendations

**1\. Reduce PostgreSQL lock contention and optimize transaction handling**

Review the transaction surrounding SELECT \* FROM payment\_accounts WHERE account\_id = ? FOR UPDATE. Keep transactions as short as possible so row locks are released quickly. Avoid holding a database transaction open while performing unrelated processing or external API calls. Where business consistency requirements allow, replace pessimistic FOR UPDATE locking with an optimistic concurrency strategy or a less restrictive locking approach. Confirm that payment\_accounts.account\_id is appropriately indexed so the lookup does not perform unnecessary work while acquiring the lock.

**2\. Correct connection\-pool saturation and database concurrency**

The PostgreSQL instance is operating at 98/100 active connections while 34 requests are waiting for locks. Review the application's database connection\-pool configuration and transaction lifecycle to ensure connections are released promptly. Do not simply increase max\_connections, because additional concurrent transactions can increase lock contention. First resolve long\-running/blocked transactions and then tune the application pool and PostgreSQL connection capacity based on measured production concurrency.

**3\. Add Datadog monitoring for early detection**

Configure Datadog monitors for the payment\-api error rate, P95/P99 latency, PostgreSQL connection utilization, database lock waits, and query duration. Alert before the database approaches the observed critical condition of 98% connection utilization. Create APM monitors for abnormal latency in postgres.query spans and error\-rate increases on the payment\-api → postgres\-payment\-db dependency. Datadog traces should also be used to track the latency contribution of the SELECT ... FOR UPDATE query after remediation to verify that it no longer dominates request execution time.

