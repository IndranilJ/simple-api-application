# Simple API Application 🚀

A lightweight **FastAPI** application containerized with Docker, tested locally with Postman, and deployable to **Google Cloud Run**.  
This project demonstrates end-to-end workflow: local dev → container → cloud deployment → infra-as-code.

---

## 📁 Project Structure

```bash
SIMPLEAPIAPPLICATION/
 └── api/
  ├── app/
  │   └── main.py          # FastAPI app entrypoint
  ├── requirements.txt     # Python dependencies
  ├── Dockerfile           # Multi-stage Docker build
  └── .dockerignore        # Ignore unnecessary files in Docker build
```

---

## 🐍 FastAPI Application

Endpoints:
- `GET /health` → Health check
- `GET /hello?name=Indranil` → Greeting
- `POST /echo` → Echo back JSON `{ "message": "..." }`

---

## ▶️ Run Locally

### 1. Install dependencies
```bash
pip install -r api/requirements.txt
```

### 2. Start FastAPI with Uvicorn
```bash
uvicorn app.main:app --reload --port 8000
```
### 3. Test with Postman

GET http://localhost:8000/ → { "Allowed methods": "/health [GET], /hello [GET], /echo [POST]" }

GET http://localhost:8000/health → { "status": "ok" }

GET http://localhost:8000/hello?name=Indranil → { "greeting": "Hello, Indranil!" }

POST http://localhost:8000/echo → body { "message": "hi" }

## 🐳 Run with Docker

### 1. Build image
```bash
cd api
docker build -t hello-api:local .
```
### 2. Run container
```bash
docker run -d --name hello-api -p 8000:8000 hello-api:local
```
### 3. Exec into container (optional)
```bash
docker exec -it hello-api /bin/sh
```
## ☁️ Deploy to Google Cloud Run

### 1. Enable services
```bash
gcloud services enable run.googleapis.com artifactregistry.googleapis.com
```
### 2. Create Artifact Registry repo
```bash
gcloud artifacts repositories create hello-api-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repo for Hello API"
```
### 3. Build & push image
```bash
docker build -t us-central1-docker.pkg.dev/<PROJECT_ID>/hello-api-repo/hello-api:latest .
docker push us-central1-docker.pkg.dev/<PROJECT_ID>/hello-api-repo/hello-api:latest
```
### 4. Deploy to Cloud Run
```bash
gcloud run deploy hello-api \
  --image us-central1-docker.pkg.dev/<PROJECT_ID>/hello-api-repo/hello-api:latest \
  --region us-central1 \
  --allow-unauthenticated
```
### 5. Test deployed service

Use the Cloud Run URL:

GET <SERVICE_URL>/health

GET <SERVICE_URL>/hello?name=Indranil

POST <SERVICE_URL>/echo

## 📦 Infrastructure as Code (Terraform)

Infra definitions are in terraform/.Run:

terraform init
terraform plan -var-file=env.tfvars
terraform apply -var-file=env.tfvars

## 🔄 CI/CD with Azure DevOps

Infra pipeline: applies Terraform to provision GCP resources.

App pipeline: builds Docker image, pushes to Artifact Registry, deploys to Cloud Run.

Pipeline YAMLs are in azure-pipelines/.

## 📝 Notes

Default port is 8000 (mapped in Dockerfile).

Swagger UI available at /docs once app is running.

ReDoc available at /redoc.