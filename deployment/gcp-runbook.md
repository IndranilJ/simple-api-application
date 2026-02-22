# GCP Deployment Runbook — Synapse

**Project ID:** `project-3a5ecdcf-cc00-4004-a9d`  
**Project Name:** `synapse-dev`  
**Account:** `indranil14jana@gmail.com`  
**Region:** `us-central1` (Iowa)  
**Shell:** Windows CMD (PowerShell noted where required)

---

## Live Service URLs

| Service | URL |
|---------|-----|
| Frontend | `https://synapse-frontend-256447952073.us-central1.run.app` |
| Backend | `https://synapse-backend-256447952073.us-central1.run.app` |
| Worker | `https://synapse-worker-256447952073.us-central1.run.app` |

---

## Architecture

```
Browser
  │ HTTPS
  ▼
Cloud Run: synapse-frontend  (Nginx, port 80, public)
  │ HTTPS — backend URL baked into JS bundle at build time
  ▼
Cloud Run: synapse-backend   (FastAPI, port 8004, public)
  │                  │
  │ Unix socket       │ TCP 6379 (Direct VPC Egress)
  ▼                  ▼
Cloud SQL          Memorystore Redis (private IP: 10.3.105.83)
(PostgreSQL 15)      ▲
  ▲                  │
  │ Unix socket       │ TCP 6379 (Direct VPC Egress)
Cloud Run: synapse-worker    (Celery, port 8080 health-check, private)
```

---

## ✅ Step 1 — Enable Required GCP APIs

```cmd
gcloud services enable run.googleapis.com sqladmin.googleapis.com redis.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com vpcaccess.googleapis.com cloudbuild.googleapis.com
```

---

## ✅ Step 2 — Create Artifact Registry

```cmd
gcloud artifacts repositories create synapse-repo --repository-format=docker --location=us-central1 --description="Synapse Docker images"
gcloud auth configure-docker us-central1-docker.pkg.dev
```

Image URL base:
```
us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/
```

---

## ✅ Step 3 — Create Cloud SQL (PostgreSQL)

```cmd
gcloud sql instances create synapse-db --database-version=POSTGRES_15 --tier=db-f1-micro --region=us-central1 --storage-type=SSD --storage-size=10GB
gcloud sql databases create synapse_db --instance=synapse-db
gcloud sql users create synapse --instance=synapse-db --password=SynapseSecret2026
```

| Property | Value |
|----------|-------|
| Instance | `synapse-db` |
| Database | `synapse_db` |
| User | `synapse` |
| Password | `SynapseSecret2026` |
| Connection name | `project-3a5ecdcf-cc00-4004-a9d:us-central1:synapse-db` |

> **Why Unix socket?** Cloud Run uses `--add-cloudsql-instances` to inject the Cloud SQL Auth Proxy as a sidecar. The app connects via `/cloudsql/<connection-name>` socket — no public IP, no TCP port exposed.

> ⚠️ **Password tip:** Avoid special characters like `@` in passwords — they break URL parsing in connection strings.

---

## ✅ Step 4 — Create Memorystore (Redis)

```cmd
gcloud redis instances create synapse-redis --size=1 --region=us-central1 --network=default --tier=basic
```

| Property | Value |
|----------|-------|
| Instance | `synapse-redis` |
| Private IP | `10.3.105.83` |
| Port | `6379` |
| Redis URL | `redis://10.3.105.83:6379/0` |

> **Why Direct VPC Egress?** Instead of a VPC Connector, Cloud Run gets a network interface directly in the default VPC. Pass `--network=default --subnet=default --vpc-egress=private-ranges-only` on all Cloud Run deploys that need Redis. Saves ~$6/month vs a dedicated VPC Connector.

---

## ✅ Step 5 — Secret Manager (Store Credentials)

> ⚠️ **Windows gotcha:** `echo value | gcloud secrets create ...` adds a trailing `\n` to the secret value, which breaks the Cloud SQL socket path. Use PowerShell `WriteAllText` instead — it writes exact bytes.

### Create secrets (PowerShell):

```powershell
# JWT Secret
[System.IO.File]::WriteAllText("C:\Temp\jwt.txt", "SYNAPSE@JWT@2026")
gcloud secrets create JWT_SECRET_KEY --data-file="C:\Temp\jwt.txt"

# Async DB URL (FastAPI — asyncpg driver)
[System.IO.File]::WriteAllText("C:\Temp\db_async.txt", "postgresql+asyncpg://synapse:SynapseSecret2026@/synapse_db?host=/cloudsql/project-3a5ecdcf-cc00-4004-a9d:us-central1:synapse-db")
gcloud secrets create DATABASE_URL --data-file="C:\Temp\db_async.txt"

# Sync DB URL (Celery worker — psycopg2 driver)
[System.IO.File]::WriteAllText("C:\Temp\db_sync.txt", "postgresql://synapse:SynapseSecret2026@/synapse_db?host=/cloudsql/project-3a5ecdcf-cc00-4004-a9d:us-central1:synapse-db")
gcloud secrets create SYNC_DATABASE_URL --data-file="C:\Temp\db_sync.txt"

# Redis URL
[System.IO.File]::WriteAllText("C:\Temp\redis.txt", "redis://10.3.105.83:6379/0")
gcloud secrets create REDIS_URL --data-file="C:\Temp\redis.txt"
```

To update an existing secret (add a new version):
```cmd
gcloud secrets versions add SECRET_NAME --data-file="C:\Temp\file.txt"
```

---

## ✅ Step 6 — Grant Service Account Permissions

```cmd
:: Get project number
for /f "tokens=*" %i in ('gcloud projects describe project-3a5ecdcf-cc00-4004-a9d --format="value(projectNumber)"') do set PROJECT_NUM=%i

:: Allow reading secrets
gcloud projects add-iam-policy-binding project-3a5ecdcf-cc00-4004-a9d --member="serviceAccount:%PROJECT_NUM%-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

:: Allow connecting to Cloud SQL
gcloud projects add-iam-policy-binding project-3a5ecdcf-cc00-4004-a9d --member="serviceAccount:%PROJECT_NUM%-compute@developer.gserviceaccount.com" --role="roles/cloudsql.client"
```

Service account: `256447952073-compute@developer.gserviceaccount.com`

---

## ✅ Step 7 — Build & Push Docker Images

### Backend

```cmd
docker build -t us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest ./api
docker push us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest
```

### Frontend

> Build AFTER Step 8a — you need the backend URL first. Use `--no-cache` to ensure `VITE_API_URL` is baked in (Docker can cache the npm build step incorrectly).

```cmd
docker build --no-cache --build-arg VITE_API_URL=https://synapse-backend-256447952073.us-central1.run.app -t us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/frontend:latest ./ui
docker push us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/frontend:latest
```

> **Why `--build-arg`?** Vite compiles React to static JS at build time. The backend URL must be embedded into the bundle — it can't change at runtime. `VITE_API_URL` is declared as `ARG` + `ENV` in `ui/Dockerfile` before `npm run build`.

---

## ✅ Step 8 — Deploy to Cloud Run

### 8a — Backend

```cmd
gcloud run deploy synapse-backend ^
  --image=us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest ^
  --region=us-central1 ^
  --platform=managed ^
  --allow-unauthenticated ^
  --port=8004 ^
  --network=default ^
  --subnet=default ^
  --vpc-egress=private-ranges-only ^
  --add-cloudsql-instances=project-3a5ecdcf-cc00-4004-a9d:us-central1:synapse-db ^
  --set-secrets="DATABASE_URL=DATABASE_URL:latest,REDIS_URL=REDIS_URL:latest,JWT_SECRET_KEY=JWT_SECRET_KEY:latest" ^
  --min-instances=1 ^
  --memory=512Mi
```

**Output URL:** `https://synapse-backend-256447952073.us-central1.run.app`

> Database tables are created automatically on first startup via FastAPI's `@app.on_event("startup")` → `init_db()`. No separate migration step needed.

### 8b — Celery Worker

> Cloud Run requires an HTTP listener on the PORT — Celery doesn't have one. We use `run_worker.py` which starts a lightweight health-check HTTP server on port 8080 alongside Celery in a daemon thread.

```cmd
gcloud run deploy synapse-worker ^
  --image=us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest ^
  --region=us-central1 ^
  --platform=managed ^
  --no-allow-unauthenticated ^
  --port=8080 ^
  --network=default ^
  --subnet=default ^
  --vpc-egress=private-ranges-only ^
  --add-cloudsql-instances=project-3a5ecdcf-cc00-4004-a9d:us-central1:synapse-db ^
  --set-secrets="SYNC_DATABASE_URL=SYNC_DATABASE_URL:latest,REDIS_URL=REDIS_URL:latest" ^
  --min-instances=1 ^
  --command="python" ^
  --args="run_worker.py" ^
  --memory=512Mi
```

> `--no-allow-unauthenticated` — the worker has no public routes; only Cloud Run infrastructure calls its health check endpoint.

### 8c — Frontend

After building with the backend URL (Step 7 Frontend):

```cmd
gcloud run deploy synapse-frontend ^
  --image=us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/frontend:latest ^
  --region=us-central1 ^
  --platform=managed ^
  --allow-unauthenticated ^
  --port=80 ^
  --memory=256Mi
```

**Output URL:** `https://synapse-frontend-256447952073.us-central1.run.app`

---

## ✅ Step 9 — Verify

```cmd
:: Check backend is alive
curl https://synapse-backend-256447952073.us-central1.run.app/

:: Check API docs
:: Open in browser: https://synapse-backend-256447952073.us-central1.run.app/docs
```

Open the frontend:
1. Register a new user
2. Create a note
3. Click **Analyze** — sentiment should appear after ~5 seconds

### Check worker logs (verify tasks processing):
```cmd
gcloud logging read "resource.labels.service_name=synapse-worker" --limit=20 --project=project-3a5ecdcf-cc00-4004-a9d
```

---

## Redeployment (After Code Changes)

### Backend or Worker changed:
```cmd
docker build -t us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest ./api
docker push us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest

:: Redeploy backend
gcloud run deploy synapse-backend --image=us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest --region=us-central1 --platform=managed --allow-unauthenticated --port=8004 --network=default --subnet=default --vpc-egress=private-ranges-only --add-cloudsql-instances=project-3a5ecdcf-cc00-4004-a9d:us-central1:synapse-db --set-secrets="DATABASE_URL=DATABASE_URL:latest,REDIS_URL=REDIS_URL:latest,JWT_SECRET_KEY=JWT_SECRET_KEY:latest" --min-instances=1 --memory=512Mi

:: Redeploy worker
gcloud run deploy synapse-worker --image=us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest --region=us-central1 --platform=managed --no-allow-unauthenticated --port=8080 --network=default --subnet=default --vpc-egress=private-ranges-only --add-cloudsql-instances=project-3a5ecdcf-cc00-4004-a9d:us-central1:synapse-db --set-secrets="SYNC_DATABASE_URL=SYNC_DATABASE_URL:latest,REDIS_URL=REDIS_URL:latest" --min-instances=1 --command="python" --args="run_worker.py" --memory=512Mi
```

### Frontend changed:
```cmd
docker build --no-cache --build-arg VITE_API_URL=https://synapse-backend-256447952073.us-central1.run.app -t us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/frontend:latest ./ui
docker push us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/frontend:latest
gcloud run deploy synapse-frontend --image=us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/frontend:latest --region=us-central1 --platform=managed --allow-unauthenticated --port=80 --memory=256Mi
```

---

## Secret Rotation

```cmd
:: 1. Write new value to a temp file (PowerShell)
[System.IO.File]::WriteAllText("C:\Temp\new_secret.txt", "NEW_VALUE_HERE")

:: 2. Add a new version
gcloud secrets versions add SECRET_NAME --data-file="C:\Temp\new_secret.txt"

:: 3. Check versions
gcloud secrets versions list SECRET_NAME

:: 4. Redeploy affected Cloud Run service to pick up :latest
```

---

## Useful Diagnostic Commands

```cmd
:: List all Cloud Run services
gcloud run services list --region=us-central1

:: View backend logs (last 50 lines)
gcloud logging read "resource.labels.service_name=synapse-backend" --limit=50 --project=project-3a5ecdcf-cc00-4004-a9d

:: View worker logs
gcloud logging read "resource.labels.service_name=synapse-worker" --limit=50 --project=project-3a5ecdcf-cc00-4004-a9d

:: Describe a service (see env vars, secrets, image)
gcloud run services describe synapse-backend --region=us-central1

:: Check Cloud SQL instance status
gcloud sql instances describe synapse-db

:: Check Redis instance
gcloud redis instances describe synapse-redis --region=us-central1

:: List secrets
gcloud secrets list

:: View secret value
gcloud secrets versions access latest --secret=DATABASE_URL
```

---

## Database Utilities (Cloud SQL Studio)

### Populate with test data (5 users, 42 notes, all tagged):
Run the `DO $$ ... END $$` block — see `deployment/seed_data.sql`.  
All test users login with password: **`TestPass1`**

### Clear all data:
```sql
TRUNCATE TABLE notetaglink, note, tag, "user" RESTART IDENTITY CASCADE;
```

### Generate bcrypt hash (for test user passwords):
```cmd
gcloud run jobs create gen-hash --image=us-central1-docker.pkg.dev/project-3a5ecdcf-cc00-4004-a9d/synapse-repo/backend:latest --region=us-central1 --command="python" --args="-c,from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('TestPass1'))"
gcloud run jobs execute gen-hash --region=us-central1 --wait
gcloud logging read "resource.labels.job_name=gen-hash" --limit=5 --format="value(textPayload)" --project=project-3a5ecdcf-cc00-4004-a9d
```

---

## 💾 Data Backup

```cmd
:: Create GCS bucket (one-time)
gcloud storage buckets create gs://synapse-db-backups-indra --location=us-central1

:: Export to GCS (run before deleting instance)
gcloud sql export sql synapse-db gs://synapse-db-backups-indra/backup-20260222.sql --database=synapse_db

:: Import from GCS (after recreating instance)
gcloud sql import sql synapse-db gs://synapse-db-backups-indra/backup-20260222.sql --database=synapse_db
```

---

## Known Gotchas & Fixes

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| `FileNotFoundError` on Cloud SQL socket | Windows `echo` adds trailing `\n` to secret → socket path becomes `/cloudsql/...\n` | Use PowerShell `WriteAllText` to write exact bytes |
| `InvalidPasswordError` on DB connect | `@` in password breaks URL parsing | Use passwords without special characters |
| Celery worker: `Connection refused localhost:5432` | `tasks.py` read `DATABASE_URL` but worker only has `SYNC_DATABASE_URL` | Priority: `SYNC_DATABASE_URL` → `DATABASE_URL` → fallback |
| psycopg2 still hits localhost even with correct URL | psycopg2 ignores `?host=` URL query param (asyncpg-specific feature) | Parse URL, extract socket path, pass via `connect_args={"host": socket_path}` |
| Worker fails health check on Cloud Run | Celery has no HTTP listener; Cloud Run requires one | `run_worker.py` starts health-check HTTP server on port 8080 in daemon thread |
| Registration fails from frontend | FastAPI CORS only allowed `localhost` | Added Cloud Run frontend URL to `allow_origins` in `main.py` |
| Frontend build cached wrong API URL | Docker cached `npm run build` layer, `VITE_API_URL` not re-baked | Use `docker build --no-cache` for frontend |

---

## Estimated Monthly Cost

| Service | Cost |
|---------|------|
| Cloud Run frontend + backend (pay per request, low traffic) | ~$0–5 |
| Cloud Run worker (min 1 always-on) | ~$10–15 |
| Cloud SQL `db-f1-micro` | ~$7 |
| Memorystore 1GB Basic | ~$16 |
| Artifact Registry (a few GB) | ~$1 |
| **Total** | **~$34–44/month** |

> New GCP accounts get **$300 free credit** for 90 days — covers everything for initial deployment.
