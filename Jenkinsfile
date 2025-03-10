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
            if (!fileExists('jenkins-scripts/')) {
                sh 'mkdir -p jenkins-scripts/'
            }
        }
    }
}
        stage('Install Prerequisites on Jenkins Server') {
            steps {
                script {
                    sh '''
                        chmod +x jenkins-scripts/*.sh
                        jenkins-scripts/install_dependencies.sh
                    '''
                }
            }
        }

        stage('Setup Kubernetes on Master & Worker Nodes') {
            steps {
                script {
                    sh '''
                        jenkins-scripts/setup_k8s_master.sh
                        jenkins-scripts/setup_k8s_worker.sh
                    '''
                }
            }
        }

        stage('Configure AWS Credentials') {
            steps {
                script {
                    sh '''
                        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                        export AWS_REGION=${AWS_REGION}
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $AWS_REGION
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
                        cat <<EOF > ${ANSIBLE_INVENTORY}
                        [k8s_master]
                        <private-ip-master> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                        [k8s_worker]
                        <private-ip-worker> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                        [monitoring]
                        <private-ip-monitoring> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                        [jenkins]
                        <private-ip-jenkins> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/Mumbai-key1.pem ansible_connection=ssh

                        [all:vars]
                        ansible_ssh_common_args='-o StrictHostKeyChecking=no'
                        EOF
                    """
                }
            }
        }

        stage('Build with Maven') {
            steps {
                sh '''
                    ${MAVEN_PATH} clean package
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ${CONTAINER_IMAGE} .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'dockerhub_cred', url: 'https://index.docker.io/v1/']) {
                        sh '''
                            docker push ${CONTAINER_IMAGE}
                        '''
                    }
                }
            }
        }

        stage('Deploy Application using Ansible') {
            steps {
                script {
                    sh '''
                        ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/deploy.yml
                    '''
                }
            }
        }
    }
}
