# SMS Checker: Deployment Architecture

This document details the architectural topology, traffic routing strategies, and observability stack for the SMS Checker application. It serves as a reference for understanding how the stable (v1) and canary (v2) environments coexist and how continuous experimentation is implemented.

## Table of Contents

- [SMS Checker: Deployment Architecture](#sms-checker-deployment-architecture)
  - [Table of Contents](#table-of-contents)
  - [1. System Context \& Capabilities](#1-system-context--capabilities)
    - [Data Flow](#data-flow)
    - [Version Strategy](#version-strategy)
  - [2. High-Level Topology](#2-high-level-topology)
  - [3. Traffic Routing Strategies](#3-traffic-routing-strategies)
    - [3.1. Access Points \& Behavior](#31-access-points--behavior)
    - [3.2. Detailed Request Flows](#32-detailed-request-flows)
      - [Path A: Production (Stable)](#path-a-production-stable)
      - [Path B: A/B Experiment (Canary)](#path-b-ab-experiment-canary)
    - [3.3. Advanced Routing Mechanics](#33-advanced-routing-mechanics)
      - [Sticky Sessions](#sticky-sessions)
      - [Version Consistency](#version-consistency)
      - [VirtualService Routing Logic](#virtualservice-routing-logic)
  - [4. Kubernetes Resources](#4-kubernetes-resources)
    - [Resource Relationships](#resource-relationships)
    - [Pod Labeling Strategy](#pod-labeling-strategy)
    - [Internal Service Communication](#internal-service-communication)
  - [5. Observability Stack](#5-observability-stack)
    - [Architecture](#architecture)
    - [Metrics Collection](#metrics-collection)
    - [Dashboards](#dashboards)
  - [6. Developer Reference](#6-developer-reference)
    - [DNS Setup](#dns-setup)
    - [Endpoints](#endpoints)
      - [Application API Endpoints](#application-api-endpoints)
    - [Configuration Management](#configuration-management)
      - [Canary Weight Configuration](#canary-weight-configuration)
      - [Secrets Management](#secrets-management)

---

## 1. System Context & Capabilities

The SMS Checker is a web application that classifies SMS messages as **spam** or **ham** (legitimate) using a machine learning model. The system consists of two main services:

- **App (Frontend)**: A Spring Boot application serving a web UI and REST API
- **Model Service**: A Python Flask service hosting the ML classification model

### Data Flow

The system follows a standard request-response pattern:

```mermaid
flowchart LR
    subgraph "SMS Classification Flow"
        User[User] -->|"1. Enter SMS text"| UI[Web UI at /sms/]
        UI -->|"2. POST /sms/"| App[App Service]
        App -->|"3. POST /predict"| Model[Model Service]
        Model -->|"4. spam/ham result"| App
        App -->|"5. Display result"| UI
    end
```

1. **User** submits text via the Web UI (`/sms/`).
2. **App Service** (Spring Boot) receives the request.
3. **Model Service** (Python Flask) performs ML inference.
4. **Result** is returned to the user.

This flow is identical for both v1 and v2; the difference lies in the internal caching behavior of v2.

### Version Strategy

To support Continuous Experimentation, two versions of the application run simultaneously:

| Feature | **v1 (Stable)** | **v2 (Canary)** |
| :--- | :--- | :--- |
| **Logic** | Direct ML processing | Adds **In-Memory Caching** |
| **Goal** | Baseline performance | Test latency reduction & resource usage |
| **Configuration** | Standard | `CACHE_MAX_SIZE=1000`, `CACHE_TTL=3600s` |
| **Behavior** | Always computes prediction | Returns cached result if hash matches |
| **Header** | None | App sends `X-Cache-Enabled: true` |

The caching mechanism uses a SHA-256 hash of the SMS content as the cache key, with FIFO eviction when the cache exceeds its maximum size. See [continuous-experimentation.md](./continuous-experimentation.md) for the full experimental design and hypothesis.

---

## 2. High-Level Topology

The following diagram illustrates the complete system topology, showing how external traffic enters the cluster and routes to specific service versions.

```mermaid
flowchart TB
    subgraph Internet["Internet"]
        User([User])
    end

    subgraph Cluster["Kubernetes Cluster"]
        subgraph Ingress["Entry Points"]
            Nginx["Nginx Ingress<br/>(team14.local)"]
            IstioGW["Istio Gateway<br/>(istio/canary.team14.local)"]
        end

        subgraph AppLayer["App Service"]
            AppV1["App v1<br/>(Stable)"]
            AppV2["App v2<br/>(Canary)"]
        end

        subgraph ModelLayer["Model Service"]
            ModelV1["Model v1<br/>(Stable)"]
            ModelV2["Model v2<br/>(Canary)"]
        end
        
        subgraph Monitoring["Observability"]
            Prometheus[(Prometheus)]
            Grafana["Grafana"]
        end
    end

    %% Routing
    User --> Nginx
    User --> IstioGW
    
    Nginx -->|"Prod Traffic (100%)"| AppV1
    IstioGW -->|"90%"| AppV1
    IstioGW -->|"10%"| AppV2
    
    %% Internal Connections (version-matched)
    AppV1 --> ModelV1
    AppV2 --> ModelV2
    
    %% Monitoring Connections
    Prometheus -.->|Scrape| AppV1 & AppV2 & ModelV1 & ModelV2
    Prometheus --> Grafana

    style AppV1 fill:#4CAF50,color:#fff
    style AppV2 fill:#FF9800,color:#fff
    style ModelV1 fill:#4CAF50,color:#fff
    style ModelV2 fill:#FF9800,color:#fff
    style Nginx fill:#326CE5,color:#fff
    style IstioGW fill:#466BB0,color:#fff
```

- **Nginx Ingress:** provides the stable production endpoint, always routing to v1 components (green).
- **Istio Gateway:** enables experimentation with weighted traffic splitting (90/10).
- **Prometheus:** scrapes metrics from all pods; **Grafana** visualizes the data.

---

## 3. Traffic Routing Strategies

The system exposes three distinct entry points.

### 3.1. Access Points & Behavior

| Hostname | Entry Controller | Routing Logic | Use Case |
| :--- | :--- | :--- | :--- |
| **`team14.local`** | Nginx Ingress | **100% Stable (v1)**. Bypasses Istio routing logic. | Production / Baseline |
| **`istio.team14.local`** | Istio Gateway | **90% Stable / 10% Canary**. Managed by VirtualService weights. | A/B Testing |
| **`canary.team14.local`** | Istio Gateway | **100% Canary (v2)**. | Dev / Verification |

### 3.2. Detailed Request Flows

#### Path A: Production (Stable)

Users on `team14.local` are guaranteed a consistent experience without experimental features.

```mermaid
sequenceDiagram
    participant U as User
    participant N as Nginx Ingress
    participant S as App Service
    participant A as App v1 Pod
    participant M as Model Service v1

    U->>N: HTTP GET /sms/ (team14.local)
    N->>S: Route to app:8080
    S->>A: Load balance to v1 pod
    Note over A: User submits SMS
    U->>N: HTTP POST /sms/ {"sms": "..."}
    N->>S: Route to app:8080
    S->>A: Forward request
    A->>M: HTTP POST /predict (no caching)
    M-->>A: {"result": "spam/ham"}
    A-->>N: JSON response
    N-->>U: HTTP response
```


#### Path B: A/B Experiment (Canary)

Users on `istio.team14.local` participate in the experiment:

```mermaid
sequenceDiagram
    participant U as User
    participant G as Istio Gateway
    participant VS as VirtualService
    participant DR as DestinationRule
    participant A1 as App v1
    participant A2 as App v2
    participant M1 as Model v1
    participant M2 as Model v2

    U->>G: HTTP GET /sms/ (istio.team14.local)
    G->>VS: Route request based on host
    
    alt 90% of traffic (stable path)
        VS->>DR: subset: v1
        DR->>A1: Route to stable pod
        Note over DR: Set user-session cookie
        A1->>M1: POST /predict (no X-Cache-Enabled header)
        M1-->>A1: ML Prediction (always computed)
        A1-->>U: Response (stable experience)
    else 10% of traffic (canary path)
        VS->>DR: subset: v2
        DR->>A2: Route to canary pod
        Note over DR: Set user-session cookie
        A2->>M2: POST /predict (X-Cache-Enabled: true)
        alt Cache Hit
            M2-->>A2: Cached Prediction (fast)
        else Cache Miss
            Note over M2: Run ML model
            M2-->>A2: New Prediction (stored in cache)
        end
        A2-->>U: Response (canary experience)
    end
```

The VirtualService performs weighted routing (90% v1, 10% v2), and the DestinationRule sets a session cookie to maintain user stickiness.

### 3.3. Advanced Routing Mechanics

#### Sticky Sessions

To ensure consistent user experience during an experiment, sticky sessions are enabled via `DestinationRule`:

```yaml
trafficPolicy:
  loadBalancer:
    consistentHash:
      httpCookie:
        name: "user-session"
        ttl: "0s"  # Session cookie (expires on browser close)
```

Once a user is assigned to v1 or v2, they remain on that version for their session.

#### Version Consistency

It is critical that App v2 *only* talks to Model v2 to test the caching logic end-to-end. To accomplish this the Model Service' VirtualService uses Istio's `sourceLabels` matching:

1. The App pod has a label `version: v1` or `version: v2`
2. The Istio sidecar (Envoy) intercepts outgoing requests to `model-service`
3. The VirtualService matches `sourceLabels.version` from the calling pod
4. Traffic is routed to the corresponding model-service subset (v1 $\rightarrow$ v1, v2 $\rightarrow$ v2)

This ensures that when testing the caching experiment, users get the complete experimental stack.

#### VirtualService Routing Logic

The App VirtualService implements host-based routing with weighted splits:

```mermaid
flowchart TB
    subgraph VS["VirtualService (app-vs)"]
        direction TB
        
        subgraph Match1["Match: istio.team14.local"]
            R1["Route"]
            R1 --> |"weight: 90"| V1["subset: v1"]
            R1 --> |"weight: 10"| V2["subset: v2"]
        end
        
        subgraph Match2["Match: canary.team14.local"]
            R2["Route"]
            R2 --> |"weight: 100"| V2b["subset: v2"]
        end
    end

    V1 --> AppV1["App v1 Pods"]
    V2 --> AppV2["App v2 Pods"]
    V2b --> AppV2

    style V1 fill:#4CAF50,color:#fff
    style V2 fill:#FF9800,color:#fff
    style V2b fill:#FF9800,color:#fff
    style AppV1 fill:#4CAF50,color:#fff
    style AppV2 fill:#FF9800,color:#fff
```

Requests to `istio.team14.local` enter the weighted routing block (90% v1, 10% v2). Requests to `canary.team14.local` bypass the split entirely and route 100% to v2, useful for developers who need to test the canary version directly.

---

## 4. Kubernetes Resources

The deployment is managed via Helm. Below is the relationship between Kubernetes native resources and Istio Custom Resource Definitions (CRDs).

### Resource Relationships

```mermaid
flowchart TB
    subgraph K8s["Standard Kubernetes"]
        DepV1[Deployment v1]
        DepV2[Deployment v2]
        Svc[Service]
        Ing[Nginx Ingress]
        CM[ConfigMap]
        SM[ServiceMonitor]
    end
    
    subgraph Istio["Istio CRDs"]
        GW[Gateway]
        VS[VirtualService]
        DR[DestinationRule]
    end

    %% Relationships
    DepV1 & DepV2 --> Svc
    Svc --> Ing
    
    GW --> VS --> DR --> Svc
    SM -.-> DepV1 & DepV2
    
    %% Styling
    style DepV1 fill:#4CAF50,color:#fff
    style DepV2 fill:#FF9800,color:#fff
    style GW fill:#466BB0,color:#fff
    style VS fill:#466BB0,color:#fff
    style DR fill:#466BB0,color:#fff
```

Standard Kubernetes resources like (Deployments, Services, Ingress, ConfigMap) handle the core application deployment. An Istio CRDs (Gateway, VirtualService, DestinationRule) layer on top provide traffic management without modifying the underlying Kubernetes resources.

### Pod Labeling Strategy

Istio relies on labels to distinguish subsets for routing:

| Component | Deployment | Labels | Image Tag |
| :--- | :--- | :--- | :--- |
| **App** | Stable | `app: app`, `version: v1` | `stable` |
| **App** | Canary | `app: app`, `version: v2` | `experimental` |
| **Model** | Stable | `app: model-service`, `version: v1` | `stable` |
| **Model** | Canary | `app: model-service`, `version: v2` | `experimental` |

### Internal Service Communication

Services communicate within the cluster using Kubernetes DNS:

| From | To | URL | Protocol |
|------|----|-----|----------|
| App | Model Service | `http://model-service:8081/predict` | HTTP |
| Prometheus | App | `http://app:8080/metrics` | HTTP |
| Prometheus | Model Service | `http://model-service:8081/metrics` | HTTP |
| Prometheus | Model Service | `http://model-service:8081/cache` | HTTP |

---

## 5. Observability Stack

We utilize a Prometheus/Grafana stack to monitor the cluster.

### Architecture

```mermaid
flowchart LR
    subgraph Pods["Application Pods"]
        A1["/metrics<br/>App v1"]
        A2["/metrics<br/>App v2"]
        M1["/metrics<br/>Model v1"]
        M2["/metrics<br/>Model v2"]
    end

    subgraph Discovery["Service Discovery"]
        SM1["ServiceMonitor<br/>(app)"]
        SM2["ServiceMonitor<br/>(model-service)"]
    end

    subgraph Stack["Monitoring Stack"]
        Prom[(Prometheus)]
        Graf["Grafana"]
    end

    SM1 -.->|discover| A1 & A2
    SM2 -.->|discover| M1 & M2

    SM1 & SM2 --> Prom
    Prom -->|query| Graf

    style A1 fill:#4CAF50,color:#fff
    style A2 fill:#FF9800,color:#fff
    style M1 fill:#4CAF50,color:#fff
    style M2 fill:#FF9800,color:#fff
```

- **Discovery:** `ServiceMonitor` resources automatically detect pods matching the configured label selectors.
- **Scraping:** Prometheus scrapes `/metrics` on all pods (App v1/v2 and Model v1/v2).
- **Visualization:** Grafana queries Prometheus and renders dashboards.

### Metrics Collection

Both services expose Prometheus metrics at the `/metrics` endpoint:

- **App**: Request counts, latencies, classification results (ham/spam probability)
- **Model Service**: Prediction counts, model inference times, cache statistics (v2)

### Dashboards

Two dashboards are automatically provisioned via ConfigMap sidecar:

1. **App Dashboard** ([`dashboards/app-dashboard.json`](../chart/dashboards/app-dashboard.json)): General health metrics including ham/spam probability distribution, prediction latency histograms, and request throughput.

2. **Experiment Dashboard**: Experiment visualization is yet to be created.

---

## 6. Developer Reference

### DNS Setup

To interact with the cluster locally, update your `/etc/hosts` file:

```bash
# Locate LoadBalancer IPs
kubectl get svc -n ingress-nginx    # Nginx IP
kubectl get svc -n istio-system     # Istio Gateway IP

# /etc/hosts Configuration
<NGINX_IP>   team14.local dashboard.local
<ISTIO_IP>   istio.team14.local canary.team14.local
```

### Endpoints

| URL | Description |
| :--- | :--- |
| `http://team14.local/sms/` | **Main UI** (Production - always v1) |
| `http://istio.team14.local/sms/` | **A/B Test UI** (90% v1 / 10% v2) |
| `http://canary.team14.local/sms/` | **Canary UI** (always v2) |
| `https://dashboard.local` | Kubernetes Dashboard (TLS) |
| `localhost:3000` | Grafana (requires port-forward) |

```bash
kubectl port-forward svc/prometheus-grafana -n team14 3000:80
```

Then navigate to `http://localhost:3000`.


#### Application API Endpoints

| Path | Method | Description | Component |
|------|--------|-------------|-----------|
| `/` | GET | Redirect to `/sms/` | App |
| `/sms/` | GET | Web UI for SMS classification | App |
| `/sms/` | POST | Submit SMS for classification (JSON: `{"sms": "..."}`) | App |
| `/version` | GET | Returns app version | App |
| `/metrics` | GET | Prometheus metrics | App |
| `/predict` | POST | ML classification (internal only) | Model Service |
| `/version` | GET | Returns model service version | Model Service |

### Configuration Management

Configuration is managed through distinct files, each authoritative for its domain:

| File | Scope | Key Settings |
|------|-------|--------------|
| [`chart/values.yaml`](../chart/values.yaml) | Kubernetes/Helm | Hostnames, replicas, Istio weights, Grafana |
| [`.env`](../.env.example) | Docker Compose | Images, ports, service URLs (local dev) |
| [`Vagrantfile`](../Vagrantfile) | VM Provisioning | Worker count, IPs, memory |

#### Canary Weight Configuration

The canary weights are defined in [`chart/values.yaml`](../chart/values.yaml):

```yaml
istio:
  canary:
    enabled: true
    v1Weight: 90
    v2Weight: 10
```

#### Secrets Management

The Helm chart supports two modes:

1. **Pre-deployed secrets** (recommended for production):
   ```yaml
   secrets:
     create: false
     name: app-secrets
   ```

2. **Chart-managed secrets** (for development):
   ```yaml
   secrets:
     create: true
     data:
       apiKey: "..."
   ```
