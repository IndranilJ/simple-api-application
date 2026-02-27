# 🏗️ Senior Platform Review: Refined Multi-Stage Terraform Strategy

As a **Senior Platform Engineer**, I've reviewed our 4-phase plan. While conceptually sound, we have a **Circular Dependency** and a **Security Gap** that must be addressed to reach production-grade maturity.

---

## � Critical Review & Adjustments

### 1. The "Edge vs Compute" Circularity (Risk)
- **Problem**: In GCP, a Load Balancer needs a **Serverless NEG** (Network Endpoint Group) which refers to a specific Cloud Run service by name.
- **Conflict**: If we deploy the Load Balancer (Phase 3) before Compute (Phase 4), it will fail because the NEGs have nothing to point to.
- **Adjustment**: Move **Global Edge (LB/WAF)** to the final stage.

### 2. Private Service Access (The Security Gap)
- **Problem**: Just setting "Private IP" on Cloud SQL isn't enough. We must provision an **IP Range Allocation** and a **VPC Peering Connection** (`servicenetworking`) to allow the Cloud Run services to actually reach the database network.
- **Adjustment**: Include "VPC Peering" in the Foundation layer.

### 3. Artifact Registry Positioning
- **Problem**: Compute needs images.
- **Adjustment**: Move **Artifact Registry** to Phase 1/2 so we can build and push the "Synapse" images before the Compute layer ever attempts to pull them.

---

## 📂 The Final 5-Step Waterfall (Isolated States)

### Phase 0: Bootstrap (One-time Manual)
- Create the GCS bucket for Terraform state (`synapse-tf-state`).

### Phase 1: Foundation (`tfstate-foundation`)
- **Networking**: Custom VPC + **Private Service Access peering**.
- **Security**: Serverless VPC Access Connector.
- **Identity**: `synapse-runtime-sa` + Workload Identity Federation (for secure CI).
- **Registry**: Artifact Registry (so images can be pushed immediately).

### Phase 2: Persistence (`tfstate-persistence`)
- **Resources**: Cloud SQL (Private), Memorystore Redis.
- **Secret Management**: Create the **Actual Secret Versions** once the DB connection string is generated.

### Phase 3: Compute (`tfstate-compute`)
- **Resources**: Backend, Worker, and Frontend Cloud Run services.
- **Access**: Private-only VPC egress; Internal-only ingress (except for Frontend).
- **Migration**: Trigger a `google_cloud_run_v2_job` to initialize the database tables.

### Phase 4: Global Edge (`tfstate-edge`)
- **Resources**: Global External Load Balancer + Serverless NEGs.
- **WAF**: Cloud Armor security policies (Rate limiting, SQLi/XSS filtering).
- **SSL**: Managed Google Certs for `api.synapse.com` and `app.synapse.com`.

---

## 🛠️ Security & Reliability Defaults
- **State Lock**: Use GCS state locking to prevent concurrent updates.
- **Encryption**: Secrets are stored in Secret Manager and injected at runtime—never stored in `.tfstate` in plain text.
- **Deletion Protection**: Enabled for Cloud SQL and GCS state buckets.

---

*This refined plan is now resilient, secure, and ready for execution. We will proceed with Phase 1.*
