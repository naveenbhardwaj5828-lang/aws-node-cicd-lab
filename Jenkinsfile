pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '849808307461'
        AWS_REGION = 'ap-south-1'
        ECR_REPOSITORY = 'aws-node-cicd-lab-repo'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        CONTAINER_NAME = 'node-app'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    def checkoutDetails = checkout scm
                    def commit = checkoutDetails.GIT_COMMIT ?: sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    def shortCommit = commit.take(7)
                    env.IMAGE_TAG = "git-${shortCommit}-build-${env.BUILD_NUMBER}"
                    env.IMAGE_URI = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"
                }
            }
        }

        stage('Test') {
            steps {
                sh 'docker build --target test -t "$ECR_REPOSITORY:test-$BUILD_NUMBER" .'
            }
        }

        stage('Build') {
            steps {
                sh 'docker build -t "$IMAGE_URI" .'
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region "$AWS_REGION" \
                      | docker login --username AWS --password-stdin "$ECR_REGISTRY"
                    docker push "$IMAGE_URI"
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker pull "$IMAGE_URI"
                    docker rm -f "${CONTAINER_NAME}-previous" 2>/dev/null || true

                    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
                        docker stop "$CONTAINER_NAME" 2>/dev/null || true
                        docker rename "$CONTAINER_NAME" "${CONTAINER_NAME}-previous"
                    fi

                    if ! docker run -d \
                      --name "$CONTAINER_NAME" \
                      --restart unless-stopped \
                      -p 3000:3000 \
                      "$IMAGE_URI"; then
                        if docker container inspect "${CONTAINER_NAME}-previous" >/dev/null 2>&1; then
                            docker rename "${CONTAINER_NAME}-previous" "$CONTAINER_NAME"
                            docker start "$CONTAINER_NAME"
                        fi
                        exit 1
                    fi
                '''

                script {
                    def healthy = sh(
                        script: '''
                            for attempt in 1 2 3 4 5; do
                                if curl --fail --silent http://127.0.0.1:3000/health >/dev/null; then
                                    exit 0
                                fi
                                sleep 2
                            done
                            exit 1
                        ''',
                        returnStatus: true
                    ) == 0

                    if (healthy) {
                        sh 'docker rm "${CONTAINER_NAME}-previous" 2>/dev/null || true'
                    } else {
                        sh '''
                            docker logs "$CONTAINER_NAME" || true
                            docker rm -f "$CONTAINER_NAME" || true

                            if docker container inspect "${CONTAINER_NAME}-previous" >/dev/null 2>&1; then
                                docker rename "${CONTAINER_NAME}-previous" "$CONTAINER_NAME"
                                docker start "$CONTAINER_NAME"
                            fi
                        '''
                        error('Deployment health check failed; previous container restored when available.')
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Published ${env.IMAGE_URI}"
        }
        always {
            sh 'docker logout "$ECR_REGISTRY" || true'
            sh 'docker image rm "$ECR_REPOSITORY:test-$BUILD_NUMBER" 2>/dev/null || true'
            script {
                if (env.IMAGE_URI?.trim()) {
                    sh 'docker image rm "$IMAGE_URI" 2>/dev/null || true'
                }
            }
            sh 'docker image prune -f || true'
        }
    }
}
