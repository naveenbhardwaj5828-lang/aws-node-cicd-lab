pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '849808307461'
        AWS_REGION = 'ap-south-1'
        ECR_REPOSITORY = 'aws-node-cicd-lab-repo'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
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
                checkout scm
                script {
                    def shortCommit = env.GIT_COMMIT.take(7)
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
    }

    post {
        success {
            echo "Published ${env.IMAGE_URI}"
        }
        always {
            sh 'docker logout "$ECR_REGISTRY" || true'
            sh 'docker image rm "$ECR_REPOSITORY:test-$BUILD_NUMBER" "$IMAGE_URI" || true'
            sh 'docker image prune -f || true'
        }
    }
}
