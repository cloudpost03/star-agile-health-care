pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "star-health"
        DOCKER_TAG = "latest"
        DOCKER_REGISTRY = "pravinkr11"
        MAVEN_PATH = sh(script: 'which mvn', returnStdout: true).trim()
        CONTAINER_IMAGE = "${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}"
        ANSIBLE_INVENTORY = "${WORKSPACE}/inventory.ini"
        AWS_ACCESS_KEY_ID = credentials('Access_key_ID')
        AWS_SECRET_ACCESS_KEY = credentials('Secret_access_key')
        AWS_REGION = "ap-south-1"
        SCRIPTS_DIR = "/var/lib/jenkins/workspace/healthcare/jenkins-scripts"
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: '*/master']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/cloudpost03/star-agile-health-care.git',
                        credentialsId: 'github_cred'
                    ]]
                ])
            }
        }

        stage('Ensure Scripts Directory Exists') {
            steps {
                sh "mkdir -p ${SCRIPTS_DIR}"
            }
        }

        stage('Copy Scripts to Workspace') {
            steps {
                sh """
                    rsync -av jenkins-scripts/ ${SCRIPTS_DIR}/
                    chmod -R 755 ${SCRIPTS_DIR}/
                """
            }
        }

        stage('Install Prerequisites on Jenkins Server') {
            steps {
                sh """
                    chmod +x ${SCRIPTS_DIR}/*.sh
                    ${SCRIPTS_DIR}/install_dependencies.sh
                """
            }
        }

        stage('Setup Kubernetes on Master & Worker Nodes') {
            steps {
                sh """
                    ${SCRIPTS_DIR}/setup_k8s_master.sh
                    ${SCRIPTS_DIR}/setup_k8s_worker.sh
                """
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                sh """
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    export AWS_REGION=${AWS_REGION}
                    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                    aws configure set region $AWS_REGION
                """
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                sh """
                    sudo apt-get install -y jq  # Install jq if not present
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                """
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                script {
                    def master_ip = sh(script: "terraform output -raw master_private_ip", returnStdout: true).trim()
                    def worker_ips = sh(script: "terraform output -json worker_private_ips | jq -r '.[]'", returnStdout: true).trim()
                    def monitoring_ip = sh(script: "terraform output -raw monitoring_private_ip", returnStdout: true).trim()
                    def jenkins_ip = sh(script: "curl -s http://169.254.169.254/latest/meta-data/local-ipv4", returnStdout: true).trim()

                    writeFile file: "${ANSIBLE_INVENTORY}", text: """
                    [k8s_master]
                    ${master_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                    [k8s_worker]
                    ${worker_ips.replaceAll("\n", "\n")} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                    [monitoring]
                    ${monitoring_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                    [jenkins]
                    ${jenkins_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                    [all:vars]
                    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
                    """
                }
            }
        }

        stage('Build with Maven') {
            steps {
                sh "${MAVEN_PATH} clean package"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${CONTAINER_IMAGE} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'dockerhub_cred', url: 'https://index.docker.io/v1/']) {
                        sh "docker push ${CONTAINER_IMAGE}"
                    }
                }
            }
        }

        stage('Deploy Application using Ansible') {
            steps {
                script {
                    if (!fileExists("ansible/deploy.yml")) {
                        error "ERROR: ansible/deploy.yml not found!"
                    }
                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/deploy.yml"
                }
            }
        }
    }
}
