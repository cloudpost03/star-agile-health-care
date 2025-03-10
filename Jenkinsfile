pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "pravinkr11/star-health:latest"
    }

    stages {

        stage('Initialize') {
            steps {
                script {
                    echo "🚀 Starting CI/CD Pipeline..."
                    sh 'whoami && pwd'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                chmod +x jenkins-scripts/*.sh
                ./jenkins-scripts/install_dependencies.sh
                '''
            }
        }

        stage('Fix Docker Permissions') {
            steps {
                sh '''
                sudo usermod -aG docker jenkins
                sudo chmod 666 /var/run/docker.sock
                '''
            }
        }

        stage('Install Kubernetes Tools') {
            steps {
                sh '''
                sudo rm -f /etc/apt/sources.list.d/kubernetes.list
                sudo apt-get update -y
                sudo apt-get install -y apt-transport-https ca-certificates curl
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.asc >/dev/null
                echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
                sudo apt-get update -y
                sudo apt-get install -y kubectl kubelet kubeadm
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t $DOCKER_IMAGE .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withDockerRegistry([credentialsId: 'docker-hub-credentials', url: '']) {
                    sh '''
                    docker login -u pravinkr11 -p ${DOCKER_PASSWORD}
                    docker push $DOCKER_IMAGE
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                kubectl apply -f k8s/deployment.yaml
                kubectl apply -f k8s/service.yaml
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline executed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs for errors."
        }
    }
}
