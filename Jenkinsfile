pipeline {
    agent none

    environment {
        SONAR_HOST_URL = 'http://sonarqube:9000'
        NEXUS_URL = 'http://nexus:8081'
        NEXUS_REPO = 'docker-hosted'
        GCR_PROJECT = 'your-gcp-project-id'
        IMAGE_NAME = 'hello-app'
        IMAGE_TAG = '1.0.0'
    }

    stages {
        stage('Clone Repo') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                git branch: 'main', credentialsId: 'admin-git-cred', url: 'https://github.com/IndranilJ/simple-api-application.git'
            }
        }

        stage('Install Dependencies') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                sh 'pip install -r requirements.txt'
            }
        }

        stage('SonarQube Code Scan') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'sonarqube-creds', usernameVariable: 'SONAR_USER', passwordVariable: 'SONAR_PASS')]) {
                    sh """
                        sonar-scanner \
                          -Dsonar.projectKey=fastapi-app \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.login=$SONAR_USER \
                          -Dsonar.password=$SONAR_PASS
                    """
                }
            }
        }

        stage('Unit Tests + Coverage') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                sh 'pytest --cov=app --cov-report=xml'
            }
            post {
                always {
                    junit 'tests/results.xml'
                    // Upload coverage report to SonarQube
                    sh 'sonar-scanner -Dsonar.coverageReportPaths=coverage.xml'
                }
            }
        }

        stage('Build Docker Image') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                sh "docker build -t $IMAGE_NAME:$IMAGE_TAG ."
            }
        }

        stage('Scan Docker Image') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                // Example using Trivy
                sh "trivy image $IMAGE_NAME:$IMAGE_TAG || true"
            }
        }

        stage('Push to Nexus Docker Registry') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        docker login $NEXUS_URL -u $NEXUS_USER -p $NEXUS_PASS
                        docker tag $IMAGE_NAME:$IMAGE_TAG $NEXUS_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG
                        docker push $NEXUS_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG
                    """
                }
            }
        }

        // CD Part
        stage('Pull from Nexus') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        docker login $NEXUS_URL -u $NEXUS_USER -p $NEXUS_PASS
                        docker pull $NEXUS_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG
                    """
                }
            }
        }

        stage('Push to GCR') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                withCredentials([file(credentialsId: 'gcr-key', variable: 'GCR_KEY')]) {
                    sh """
                        gcloud auth activate-service-account --key-file=$GCR_KEY
                        gcloud auth configure-docker
                        docker tag $NEXUS_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG gcr.io/$GCR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
                        docker push gcr.io/$GCR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
                    """
                }
            }
        }

        stage('Terraform Deploy') {
            agent { label 'python-sonar-terraform-agent' }
            steps {
                withCredentials([file(credentialsId: 'gcr-key', variable: 'GCR_KEY')]) {
                    sh """
                        export GOOGLE_APPLICATION_CREDENTIALS=$GCR_KEY
                        terraform init
                        terraform apply -auto-approve
                    """
                }
            }
        }
    }
}
