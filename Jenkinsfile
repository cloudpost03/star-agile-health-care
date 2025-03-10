pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }
    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/cloudpost03/star-agile-health-care.git'
            }
        }

        stage('Ensure Scripts Directory Exists') {
            steps {
                script {
                    if (!fileExists('jenkins-script's')) {
                        sh 'mkdir -p jenkins-scripts'
                    }
                }
            }
        }

        stage('Install Prerequisites on Jenkins Server') {
            steps {
                sh 'chmod +x jenkins-scripts/*.sh'
                sh './jenkins-scripts/install_prerequisites.sh'
            }
        }

        stage('Setup Kubernetes on Master & Worker Nodes') {
            steps {
                sh './jenkins-scripts/setup_kubernetes.sh'
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                sh './jenkins-scripts/configure_aws.sh'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                sh './jenkins-scripts/terraform_apply.sh'
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                sh './jenkins-scripts/generate_inventory.sh'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh './jenkins-scripts/build_docker.sh'
            }
        }

        stage('Push Docker Image') {
            steps {
                sh './jenkins-scripts/push_docker.sh'
            }
        }

        stage('Deploy Application using Ansible') {
            steps {
                sh './jenkins-scripts/deploy_ansible.sh'
            }
        }
    }
}
