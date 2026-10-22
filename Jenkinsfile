pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 10, unit: 'MINUTES')
    }

    parameters {
        booleanParam(
            name: 'FORCE_FAULTY',
            defaultValue: false,
            description: 'Build a deliberately faulty version to test automatic rollback'
        )
    }

    environment {
        DOCKER_IMAGE = 'akashmi0413/surplus-food-portal'
        DOCKER_CREDENTIALS = 'dockerhub-cred'
        KUBE_DEPLOYMENT = 'surplus-food-portal'
        KUBE_CONTAINER = 'portal'
        PATH = '/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Validate Files') {
            steps {
                sh '''
                    set -eu
                    test -s index.html
                    test -s Dockerfile
                    test -s deployment.yaml
                    test -s Jenkinsfile
                '''
            }
        }

        stage('Parallel Validation') {
            parallel {
                stage('HTML Validation') {
                    steps {
                        sh '''
                            set -eu
                            grep -q "Surplus Food Redistribution Portal" index.html
                            grep -q "foodTable" index.html
                            grep -q "redistributedCount" index.html
                            echo "HTML validation passed"
                        '''
                    }
                }

                stage('Dockerfile Validation') {
                    steps {
                        sh '''
                            set -eu
                            docker --version
                            docker build --check -f Dockerfile .
                        '''
                    }
                }

                stage('Kubernetes Manifest Validation') {
                    steps {
                        sh '''
                            set -eu
                            kubectl config current-context
                            kubectl apply --dry-run=client -f deployment.yaml
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def faultFlag = params.FORCE_FAULTY ? 'true' : 'false'
                    def imageTag = "${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}"

                    sh """
                        docker build \
                            --build-arg FAULTY=${faultFlag} \
                            -t ${imageTag} \
                            -t ${env.DOCKER_IMAGE}:latest \
                            .
                    """
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker rm -f surplus-food-test >/dev/null 2>&1 || true

                    docker run -d \
                        --name surplus-food-test \
                        -p 127.0.0.1:18080:80 \
                        "$DOCKER_IMAGE:$BUILD_NUMBER"

                    cleanup() {
                        docker rm -f surplus-food-test >/dev/null 2>&1 || true
                    }

                    trap cleanup EXIT

                    attempt=0

                    until curl -fsS http://127.0.0.1:18080/ >/dev/null; do
                        attempt=$((attempt + 1))

                        if [ "$attempt" -ge 15 ]; then
                            docker logs surplus-food-test
                            exit 1
                        fi

                        sleep 2
                    done

                    curl -fsS http://127.0.0.1:18080/ \
                        | grep -q "Surplus Food Redistribution Portal"

                    if [ "$FORCE_FAULTY" = "false" ]; then
                        curl -fsS http://127.0.0.1:18080/health.html \
                            | grep -q "OK"
                    fi

                    echo "Container test completed"
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        set +x
                        set -eu

                        echo "$DOCKER_PASSWORD" \
                            | docker login \
                                -u "$DOCKER_USER" \
                                --password-stdin

                        docker push "$DOCKER_IMAGE:$BUILD_NUMBER"
                        docker push "$DOCKER_IMAGE:latest"

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def imageTag = "${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}"

                    sh '''
                        set -eu
                        kubectl apply -f deployment.yaml
                    '''

                    sh """
                        kubectl set image \
                            deployment/${env.KUBE_DEPLOYMENT} \
                            ${env.KUBE_CONTAINER}=${imageTag}
                    """

                    int rolloutResult = sh(
                        script: """
                            kubectl rollout status \
                                deployment/${env.KUBE_DEPLOYMENT} \
                                --timeout=90s
                        """,
                        returnStatus: true
                    )

                    if (rolloutResult != 0) {
                        echo 'ROLLOUT FAILED. Starting automatic rollback.'

                        int rollbackResult = sh(
                            script: """
                                kubectl rollout undo \
                                    deployment/${env.KUBE_DEPLOYMENT}
                            """,
                            returnStatus: true
                        )

                        if (rollbackResult != 0) {
                            error('Automatic rollback command failed. Manual intervention required.')
                        }

                        int recoveryResult = sh(
                            script: """
                                kubectl rollout status \
                                    deployment/${env.KUBE_DEPLOYMENT} \
                                    --timeout=90s
                            """,
                            returnStatus: true
                        )

                        if (recoveryResult != 0) {
                            error('Rollback was triggered, but the previous deployment did not become ready.')
                        }

                        sh """
                            kubectl get deployment ${env.KUBE_DEPLOYMENT}
                            kubectl get pods -l app=surplus-food-portal
                        """

                        error('Deployment failed. Previous stable version restored successfully.')
                    }

                    sh """
                        kubectl get deployment ${env.KUBE_DEPLOYMENT}
                        kubectl get pods -l app=surplus-food-portal
                    """
                }
            }
        }

        stage('Archive Build Artifacts') {
            steps {
                archiveArtifacts(
                    artifacts: 'index.html,Dockerfile,Jenkinsfile,deployment.yaml',
                    fingerprint: true
                )
            }
        }
    }

    post {
        always {
            sh '''
                docker rm -f surplus-food-test >/dev/null 2>&1 || true
            '''
        }

        success {
            echo 'Portal built, tested, pushed and deployed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the console log for the failing stage and recovery status.'
        }
    }
}