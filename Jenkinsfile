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
                    sh 'mkdir -p jenkins-scripts/'
                }
            }
        }

        stage('Copy Scripts to Workspace') {
            steps {
                script {
                    sh 'rsync -av --ignore-existing jenkins-scripts/ /var/lib/jenkins/workspace/healthcare/jenkins-scripts/'
                }
            }
        }

        stage('Install Prerequisites on Jenkins Server') {
            steps {
                script {
                    sh '''
                        chmod +x /var/lib/jenkins/workspace/healthcare/jenkins-scripts/*.sh
                        /var/lib/jenkins/workspace/healthcare/jenkins-scripts/install_dependencies.sh
                    '''
                }
            }
        }

        stage('Setup Kubernetes on Master & Worker Nodes') {
            steps {
                script {
                    sh '''
                        /var/lib/jenkins/workspace/healthcare/jenkins-scripts/setup_k8s_master.sh
                        /var/lib/jenkins/workspace/healthcare/jenkins-scripts/setup_k8s_worker.sh
                    '''
                }
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                script {
                    sh '''
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                        aws configure set region ${AWS_REGION}
                    '''
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                script {
                    sh '''
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Generate Ansible Inventory') {
            steps {
                script {
                    sh """
                        echo "[k8s_master]" > ${ANSIBLE_INVENTORY}
                        echo "<private-ip-master> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh" >> ${ANSIBLE_INVENTORY}

                        echo "[k8s_worker]" >> ${ANSIBLE_INVENTORY}
                        echo "<private-ip-worker> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh" >> ${ANSIBLE_INVENTORY}

                        echo "[monitoring]" >> ${ANSIBLE_INVENTORY}
                        echo "<private-ip-monitoring> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh" >> ${ANSIBLE_INVENTORY}

                        echo "[jenkins]" >> ${ANSIBLE_INVENTORY}
                        echo "<private-ip-jenkins> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh" >> ${ANSIBLE_INVENTORY}

                        echo "[all:vars]" >> ${ANSIBLE_INVENTORY}
                        echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> ${ANSIBLE_INVENTORY}
                    """
                }
            }
        }

        stage('Build with Maven') {
            steps {
                sh '${MAVEN_PATH} clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${CONTAINER_IMAGE} .'
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'dockerhub_cred', url: 'https://index.docker.io/v1/']) {
                        sh 'docker push ${CONTAINER_IMAGE}'
                    }
                }
            }
        }

        stage('Deploy Application using Ansible') {
            steps {
                script {
                    sh 'ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/deploy.yml'
                }
            }
        }
    }
}
