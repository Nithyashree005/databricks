# Dynatrace Smartscape Topology & PurePath Analysis Report

## Smartscape Topology Health Audit

Based on inspection of `dynatrace_smartscape_purepath.json`, the following health status and resource metrics were identified across the 5-tier Smartscape model:

| Smartscape Tier | Entity Name / Identifier | Technology / OS / Framework | Health Status | Key Performance / Saturation Metric |
|---|---|---|---|---|
| **Application** | Enterprise E-Commerce Storefront / APP-STOREFRONT | E-Commerce Application | CRITICAL | Apdex: 0.42 |
| **Service** | OrderProcessingService / SERVICE-88A92 | Spring Boot 3.1.2 | CRITICAL | JVM Heap: 4012 MB / 4096 MB, 97.9% saturated |
| **Process Group** | OrderServices Java Process Group / PG-JAVA-ORDER | Java 17 (OpenJDK HotSpot) | CRITICAL | 2 processes |
| **Host** | prod-app-worker-01.ec2.internal / HOST-99A1 | Linux 5.15.0 | CRITICAL | 30.8 GB / 32 GB memory used, 96.25% utilization |
| **Datacenter** | AWS us-east-1 / DC-EAST-1 | AWS Datacenter | HEALTHY | Datacenter healthy |

### Specific Tier Saturation Questions

**Which application is experiencing user-facing degradation, and what is its Apdex score?**

- *Application Name & ID:* Enterprise E-Commerce Storefront / APP-STOREFRONT
- *Apdex Score:* 0.42
- *Impact Assessment:* The application is in CRITICAL status with a low Apdex score of 0.42, indicating significant user-facing performance degradation.

**Which service is the primary bottleneck, and what are its memory consumption metrics?**

- *Service Name & ID:* OrderProcessingService / SERVICE-88A92
- *Framework:* Spring Boot 3.1.2
- *JVM Heap Used vs. Max Heap (MB):* 4012 MB / 4096 MB
- *Heap Saturation Percentage:* 97.9%

**Identify the underlying host and process group hosting the degraded service:**

- *Host Name & ID:* prod-app-worker-01.ec2.internal / HOST-99A1
- *Host Memory Used vs. Total (GB):* 30.8 GB / 32 GB (96.25% utilized)
- *Process Group Name & ID:* OrderServices Java Process Group / PG-JAVA-ORDER
- *Technology Stack:* Java 17 (OpenJDK HotSpot), running on Linux 5.15.0

---

## Dynatrace PurePath Code-Level Trace Breakdown

The PurePath trace `PP-9821410294-819` for `POST /api/v2/orders/checkout` shows the request execution path leading to JVM heap exhaustion.

### PurePath Call Tree Breakdown

| Step | Class Name | Method Name | Duration (ms) | Error? | Exception / Error Details |
|---|---|---|---|---|---|
| 1 | org.springframework.web.servlet.DispatcherServlet | doDispatch | 3150 | YES | Error propagated through request |
| 2 | com.enterprise.order.controller.OrderCheckoutController | processCheckout | 3145 | YES | Error propagated during checkout |
| 3 | com.enterprise.order.service.OrderServiceImpl | createAndCacheOrder | 3130 | YES | Error occurred while creating and caching order |
| 4 | com.enterprise.order.cache.OrderCache | addToCache | 2850 | YES | java.lang.OutOfMemoryError: Java heap space |

### Diagnostic Findings

**Trace Overview:**

- *Trace ID:* PP-9821410294-819
- *Entry Point (HTTP Method & URI):* POST /api/v2/orders/checkout
- *Total Request Duration:* 3150 ms
- *Top-Level Error Message:* java.lang.OutOfMemoryError: Java heap space

**Root Cause Class & Method:**

- *Failing Class Name:* com.enterprise.order.cache.OrderCache
- *Failing Method Name:* addToCache
- *Execution Duration in Method (ms):* 2850 ms
- *Exact Exception Thrown:* java.lang.OutOfMemoryError: Java heap space
- *Code Vulnerability / Defect Detail (why heap memory was exhausted):* A static unbounded `ConcurrentHashMap` was storing `OrderSession` tokens without an effective size limit or eviction mechanism. The continuously growing cache consumed the available 4 GB JVM heap, ultimately causing `OutOfMemoryError`.

---

## Remediation & Configuration Recommendations

**Application Code / Cache Replacement:**

- *Recommendation:* Replace or redesign the static unbounded `ConcurrentHashMap` used by `OrderCache`. Implement a bounded cache with maximum-size and time-based expiration policies so old `OrderSession` entries are automatically evicted. A cache implementation such as Caffeine can provide maximum-size and TTL-based eviction. This addresses the underlying memory leak rather than simply increasing JVM heap size.

**Dynatrace Davis AI Anomaly Detection & Alerting:**

- *Recommendation:* Configure Dynatrace monitoring and Davis AI anomaly detection for JVM heap consumption and abnormal memory growth. Generate alerts before the heap reaches critical saturation so operations teams can investigate sustained heap growth before an `OutOfMemoryError` occurs. The current 97.9% heap saturation should be treated as a critical condition.

**Infrastructure & Container Memory Governance:**

- *Recommendation:* Review JVM `-Xmx` settings and the container or workload memory limit to ensure adequate headroom between the JVM maximum heap and the container memory limit. Configure appropriate Kubernetes/container memory requests and limits if the service is containerized. After correcting the unbounded cache, perform load testing and monitor heap usage and garbage-collection behavior in Dynatrace to verify that memory returns to a stable baseline instead of continually increasing.
