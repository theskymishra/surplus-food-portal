
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'akashmi0413/surplus-food-portal'
        K8S_DEPLOYMENT = 'surplus-food-portal'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                }
                sh '''
                    docker build -t $DOCKER_IMAGE:$IMAGE_TAG .
                    docker tag $DOCKER_IMAGE:$IMAGE_TAG $DOCKER_IMAGE:latest
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $DOCKER_IMAGE:$IMAGE_TAG
                        docker push $DOCKER_IMAGE:latest
                        docker logout
                    '''
                }
            }
        }

        
stage('Deploy to Kubernetes') {
    steps {
        sh '''
            kubectl apply -f deployment.yaml
            kubectl set image deployment/$K8S_DEPLOYMENT \
                portal=$DOCKER_IMAGE:$IMAGE_TAG
            kubectl rollout status deployment/$K8S_DEPLOYMENT --timeout=180s
            kubectl get deployment $K8S_DEPLOYMENT
            kubectl get pods -l app=surplus-food-portal
        '''
    }
}

    }

    post {
        success {
            echo 'CI/CD completed successfully.'
        }
        failure {
            echo 'CI/CD failed. Check the Console Output.'
        }
    }
}
