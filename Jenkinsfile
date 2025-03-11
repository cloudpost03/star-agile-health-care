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
        SCRIPTS_DIR = "/var/lib/jenkins/workspace/star-agile-health-care/jenkins-scripts"
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

        stage('Fetch EC2 Private IPs') {
            steps {
                script {
                    env.K8S_MASTER_IP = sh(script: "terraform output -raw master_private_ip", returnStdout: true).trim()
                    env.K8S_WORKER_IPS = sh(script: "terraform output -json worker_private_ips | jq -r '.[]'", returnStdout: true).trim()
                    env.MONITORING_IP = sh(script: "terraform output -raw monitoring_private_ip", returnStdout: true).trim()
                    env.JENKINS_IP = sh(script: "curl -s http://169.254.169.254/latest/meta-data/local-ipv4", returnStdout: true).trim()
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

        stage('Update /etc/hosts on Jenkins Server') {
            steps {
                script {
                    sh """
                        echo "Updating /etc/hosts with Kubernetes nodes"
                        sudo sed -i '/# K8s Cluster Hosts Start/,/# K8s Cluster Hosts End/d' /etc/hosts
                        
                        echo "# K8s Cluster Hosts Start" | sudo tee -a /etc/hosts
                        echo "${K8S_MASTER_IP}  k8s-master" | sudo tee -a /etc/hosts
                        
                        for worker in ${K8S_WORKER_IPS}; do
                            echo "\$worker  k8s-worker" | sudo tee -a /etc/hosts
                        done
                        
                        echo "${MONITORING_IP}  k8s-monitoring" | sudo tee -a /etc/hosts
                        echo "${JENKINS_IP}  jenkins-server" | sudo tee -a /etc/hosts
                        echo "# K8s Cluster Hosts End" | sudo tee -a /etc/hosts
                        
                        cat /etc/hosts
                    """
                }
            }
        }

        stage('Build with Maven') {
            steps {
                sh "${MAVEN_PATH} clean package"
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    sh "docker build -t ${CONTAINER_IMAGE} ."
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
