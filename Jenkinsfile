pipeline {
    // agent none
    agent { label 'agent-python' }

    environment {
        SONAR_HOST_URL = 'http://sonarqube:9000'
        NEXUS_URL = 'http://nexus:8081'
        NEXUS_DOCKER_URL = 'localhost:8081' //because agent docker is sharing local docker and in local, nexus is running as localhost:8081
        NEXUS_REPO = 'docker-hosted'
        GCR_PROJECT = 'your-gcp-project-id'
        IMAGE_NAME = 'hello-app'
        IMAGE_TAG = '1.0.0'
    }

    stages {
        stage('Clone Repo') {
            steps {
                deleteDir()
                git branch: "master", url: 'https://github.com/IndranilJ/simple-api-application.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                python3 -m venv venv
                . venv/bin/activate
                pip install --upgrade pip
                pip install -r api/requirements.txt
                '''
            }
        }

        stage('SonarQube Code Scan') {
            steps {
                withCredentials([string(credentialsId: 'admin-sq-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        sonar-scanner \
                          -Dsonar.projectKey=fastapi-app \
                          -Dsonar.sources=./api \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.token=$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Unit Tests + Coverage') {
            steps {
                sh '''
                python3 -m venv venv
                . venv/bin/activate
                pytest --cov=app --cov-report=xml --junitxml=api/tests/results.xml
                '''
                // sh 'pytest --cov=app --cov-report=xml'
            }
            post {
                always {
                    junit 'api/tests/results.xml'
                    // Upload coverage report to SonarQube
                    withCredentials([string(credentialsId: 'admin-sq-token', variable: 'SONAR_TOKEN')]) {
                        sh """sonar-scanner \
                        -Dsonar.projectKey=fastapi-app \
                        -Dsonar.host.url=$SONAR_HOST_URL \
                        -Dsonar.token=$SONAR_TOKEN \
                        -Dsonar.python.coverage.reportPaths=coverage.xml \
                        -Dsonar.coverage.exclusions=**/tests/**"""
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t $IMAGE_NAME:$IMAGE_TAG api/"
            }
        }

        stage('Scan Docker Image') {
            steps {
                // Example using Trivy
                sh "trivy image $IMAGE_NAME:$IMAGE_TAG || true"
            }
        }

        stage('Push to Nexus Docker Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'admin-nexus-cred', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        docker login http://$NEXUS_DOCKER_URL -u $NEXUS_USER -p $NEXUS_PASS
                        docker tag $IMAGE_NAME:$IMAGE_TAG $NEXUS_DOCKER_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG
                        docker push $NEXUS_DOCKER_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG
                    """
                }
            }
        }

        // // CD Part
        // stage('Pull from Nexus') {
        //     agent { label 'agent-python' }
        //     steps {
        //         withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
        //             sh """
        //                 docker login $NEXUS_URL -u $NEXUS_USER -p $NEXUS_PASS
        //                 docker pull $NEXUS_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG
        //             """
        //         }
        //     }
        // }

        // stage('Push to GCR') {
        //     agent { label 'agent-python' }
        //     steps {
        //         withCredentials([file(credentialsId: 'gcr-key', variable: 'GCR_KEY')]) {
        //             sh """
        //                 gcloud auth activate-service-account --key-file=$GCR_KEY
        //                 gcloud auth configure-docker
        //                 docker tag $NEXUS_URL/$NEXUS_REPO/$IMAGE_NAME:$IMAGE_TAG gcr.io/$GCR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
        //                 docker push gcr.io/$GCR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
        //             """
        //         }
        //     }
        // }

        // stage('Terraform Deploy') {
        //     agent { label 'agent-python' }
        //     steps {
        //         withCredentials([file(credentialsId: 'gcr-key', variable: 'GCR_KEY')]) {
        //             sh """
        //                 export GOOGLE_APPLICATION_CREDENTIALS=$GCR_KEY
        //                 terraform init
        //                 terraform apply -auto-approve
        //             """
        //         }
        //     }
        // }
    }
}