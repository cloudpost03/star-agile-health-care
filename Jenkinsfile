pipeline {
    agent any

    environment {
        IMAGE_NAME = 'pravinkr11/star-health'
        IMAGE_TAG = 'latest'
        DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'  // Jenkins credentials ID
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', credentialsId: 'bitbucket-credentials', url: 'git@bitbucket.org:your-repo.git'
            }
        }

        stage('Build Application') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Verify JAR File') {
            steps {
                sh 'ls -l target/'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh 'docker push ${IMAGE_NAME}:${IMAGE_TAG}'
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline execution completed!"
        }
    }
}
