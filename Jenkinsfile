
pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        DOCKER_IMAGE = 'karthikops/trend-app'
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER = 'trend-eks'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t "$DOCKER_IMAGE:$BUILD_NUMBER" .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x
                        export DOCKER_CONFIG=$(mktemp -d)
                        trap 'docker logout >/dev/null 2>&1 || true; rm -rf "$DOCKER_CONFIG"' EXIT

                        echo "$DOCKER_TOKEN" | docker login \
                            --username "$DOCKER_USER" \
                            --password-stdin

                        docker push "$DOCKER_IMAGE:$BUILD_NUMBER"
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig \
                        --region "$AWS_REGION" \
                        --name "$EKS_CLUSTER"

                    kubectl apply -f k8s/

                    kubectl set image deployment/trend-app \
                        trend-app="$DOCKER_IMAGE:$BUILD_NUMBER"
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl rollout status deployment/trend-app \
                        --timeout=180s

                    kubectl get pods -l app=trend-app
                    kubectl get service trend-app-service
                '''
            }
        }
    }

    post {
        success {
            echo 'Trend application deployed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
