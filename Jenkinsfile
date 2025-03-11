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
                script {
                    sh "mkdir -p ${SCRIPTS_DIR}"
                }
            }
        }

        stage('Copy Scripts to Workspace') {
            steps {
                script {
                    sh """
                        rsync -av jenkins-scripts/ ${SCRIPTS_DIR}/
                        chmod -R 755 ${SCRIPTS_DIR}/
                    """
                }
            }
        }

        stage('Install Prerequisites on Jenkins Server') {
            steps {
                script {
                    sh """
                        chmod +x ${SCRIPTS_DIR}/*.sh
                        ${SCRIPTS_DIR}/install_dependencies.sh
                    """
                }
            }
        }

        stage('Setup Kubernetes on Master & Worker Nodes') {
            steps {
                script {
                    sh """
                        ${SCRIPTS_DIR}/setup_k8s_master.sh
                        ${SCRIPTS_DIR}/setup_k8s_worker.sh
                    """
                }
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                script {
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
        }

        stage('Terraform Init & Apply') {
            steps {
                script {
                    sh """
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    """
                }
            }
        }

        stage('Fetch EC2 Private IPs') {
            steps {
                script {
                    env.K8S_MASTER_IP = sh(script: "cd terraform && terraform output -raw k8s_master_private_ip", returnStdout: true).trim()
                    env.K8S_WORKER_IPS = sh(script: "cd terraform && terraform output -json k8s_worker_private_ips | jq -r '.[]'", returnStdout: true).trim()
                    env.MONITORING_IP = sh(script: "cd terraform && terraform output -raw monitoring_private_ip", returnStdout: true).trim()
                    env.JENKINS_IP = sh(script: "cd terraform && terraform output -raw jenkins_private_ip", returnStdout: true).trim()
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                script {
                    sh """
                        cat <<EOF > ${ANSIBLE_INVENTORY}
                        [k8s_master]
                        ${K8S_MASTER_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_connection=ssh

                        [k8s_worker]
                        ${K8S_WORKER_IPS} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_connection=ssh

                        [monitoring]
                        ${MONITORING_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_connection=ssh

                        [jenkins]
                        ${JENKINS_IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_connection=ssh

                        [all:vars]
                        ansible_ssh_common_args='-o StrictHostKeyChecking=no'
                        EOF
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
                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/deploy.yml"
                }
            }
        }
    }
}
