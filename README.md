# Surplus Food Portal – CI/CD Pipeline

## Project Overview

The Surplus Food Portal is a web application designed to display surplus food available for collection. It demonstrates an automated **CI/CD pipeline using Jenkins, Docker, and Kubernetes**.

The pipeline checks out source code from GitHub, builds a Docker image, pushes it to Docker Hub, and deploys the application to a local Kubernetes cluster.

## Technologies Used

- **Frontend:** HTML, CSS, JavaScript
- **Version Control:** Git and GitHub
- **CI/CD:** Jenkins
- **Containerization:** Docker
- **Container Registry:** Docker Hub
- **Orchestration:** Kubernetes (Docker Desktop)
- **Web Server:** Nginx

## Project Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
Jenkins Pipeline
   |
   v
Build Docker Image
   |
   v
Push Image to Docker Hub
   |
   v
Deploy to Kubernetes
   |
   v
Surplus Food Portal
```

## Repository Structure

```text
surplus-food-portal/
├── index.html
├── Dockerfile
├── Jenkinsfile
├── deployment.yaml
├── .gitignore
└── README.md
```

## CI/CD Pipeline Stages

1. **Checkout:** Retrieves the application source code from GitHub.
2. **Build:** Builds a Docker image using the Dockerfile.
3. **Push:** Pushes the versioned image and the `latest` tag to Docker Hub.
4. **Deploy:** Applies the Kubernetes configuration and updates the deployment with the newly built image.
5. **Verification:** Checks the Kubernetes rollout status and deployment details.

## Docker Hub Image

Docker Hub repository:

https://hub.docker.com/r/akashmi0413/surplus-food-portal

The pipeline publishes images using build-number tags, such as:

```text
akashmi0413/surplus-food-portal:2
akashmi0413/surplus-food-portal:latest
```

## Kubernetes Deployment

The Kubernetes configuration defines:

- A Deployment with **2 replicas**
- A NodePort Service
- Readiness and liveness probes
- A health-check endpoint at `/health.html`
- A rolling-update deployment strategy

The application uses port `80` inside the container and NodePort `30080` for external access.

## Prerequisites

Install and configure the following:

- Git
- Docker Desktop
- Jenkins
- kubectl
- A running Kubernetes cluster in Docker Desktop
- A GitHub repository
- A Docker Hub account

Configure Jenkins with a Docker Hub username and access token using the credential ID `dockerhub-cred`.

## How to Run the Project

### 1. Clone the repository

```bash
git clone https://github.com/theskymishra/surplus-food-portal.git
cd surplus-food-portal
```

### 2. Build the Docker image

```bash
docker build -t akashmi0413/surplus-food-portal:latest .
```

### 3. Run the application using Docker

```bash
docker run --rm -p 8080:80 akashmi0413/surplus-food-portal:latest
```

Open:

http://localhost:8080

### 4. Deploy to Kubernetes

Ensure Docker Desktop Kubernetes is running and the correct context is selected.

```bash
kubectl config use-context docker-desktop
kubectl apply -f deployment.yaml
kubectl rollout status deployment/surplus-food-portal
```

### 5. Verify the deployment

```bash
kubectl get deployments
kubectl get pods -l app=surplus-food-portal
kubectl get services
```

### 6. Access the application

For reliable access on macOS, run:

```bash
kubectl port-forward service/surplus-food-portal 8080:80
```

Keep the command running and open:

http://localhost:8080

### 7. Check the health endpoint

In another Terminal window, run:

```bash
curl http://localhost:8080/health.html
```

Expected response:

```text
OK
```

## Jenkins Configuration

Create a Jenkins Pipeline job with the following configuration:

- **Job Name:** `Surplus-Food-Portal-CI-CD`
- **Pipeline Definition:** Pipeline script from SCM
- **SCM:** Git
- **Repository URL:** `https://github.com/theskymishra/surplus-food-portal.git`
- **Branch:** `*/main`
- **Script Path:** `Jenkinsfile`

Configure the Docker Hub credential in Jenkins using the ID `dockerhub-cred`.

The pipeline can be triggered manually using **Build Now**. Poll SCM is not required.

## Verification Results

The successful Jenkins build verified that:

- The source code was checked out from GitHub.
- The Docker image was built and pushed to Docker Hub.
- The Kubernetes Deployment and Service were applied.
- The application image was updated in Kubernetes.
- The rollout completed successfully.
- Both application replicas reached the Ready state.

## Conclusion

This project demonstrates an end-to-end CI/CD workflow for a web application using GitHub, Jenkins, Docker, Docker Hub, and Kubernetes. It automates image creation, publishing, and deployment while using multiple replicas and health probes to support application availability.

## Author

**Akash Mishra**

GitHub: https://github.com/theskymishra

Docker Hub: https://hub.docker.com/u/akashmi0413
