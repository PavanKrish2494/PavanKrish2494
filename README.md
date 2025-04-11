## Project Overview

- **Terraform**: Infrastructure as Code (IaC) tool to create AWS infrastructure such as EC2 instances and EKS clusters.
- **GitHub**: Source code management.
- **Jenkins**: CI/CD automation tool.
- **SonarQube**: Code quality analysis and quality gate tool.
- **NPM**: Build tool for NodeJS.
- **Aqua Trivy**: Security vulnerability scanner.
- **Docker**: Containerization tool to create images.
- **AWS ECR**: Repository to store Docker images.
- **AWS EKS**: Container management platform.
- **Prometheus & Grafana**: Monitoring and alerting tools.

## Pre-requisites
1. **AWS Account**: Ensure you have an AWS account. [Create an AWS Account](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-creating.html)
2. **AWS CLI**: Install AWS CLI on your local machine. [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **VS Code (Optional)**: Download and install VS Code as a code editor. [VS Code Download](https://code.visualstudio.com/download)
4. **Install Terraform in Windows**: Download and install Terraform in Windows [Terraform in Windows](https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-windows-bash)

## Configuration
### AWS Setup
1. **IAM User**: Create an IAM user and generate the access and secret keys to configure your machine with AWS.
2. **Key Pair**: Create a key pair named `pavan-key` for accessing your EC2 instances.

1. **Clone the Repository** (Open Command Prompt & run below):
   ```bash
   git clone https://github.com/PavanKrish2494/PavanKrish2494.git
   cd PavanKrish2494
   git checkout assigment     # Ths is the Branch where code is Present
   code .   # this command will open VS code in backend
   ```
2. **Initialize and Apply Terraform**:
      - Creation of S3 Bucket and DynamoDB table for storing and locking of statefile
      - Open and first implement which is on backend.tf
     - Run the following commands:
     ```bash
     aws configure
     terraform init
     terraform apply --auto-approve
     ```
3. **After exectue all the blocks in the terraform and scripting is mentioned on script.sh and with the use of provisioners packages and dependncies will install inside the EC2 Instance**:

4. **NOTE:I have allowed all traffic because of Assignment but should not implement on realtime environments especially on Production, which will cause a security breach**
   
5. ## SonarQube Configuration
1. **Login Credentials**: Use `admin` for both username and password.
2. **Generate SonarQube Token**:
   - Create a token under `Administration → Security → Users → Tokens`.
   - Save the token for integration with Jenkins.

6. ## Jenkins Configuration
1. **Add Jenkins Credentials**:
   - Add the SonarQube token, AWS access key, and secret key in `Manage Jenkins → Credentials → System → Global credentials`.
2. **Install Required Plugins**:
   - Install plugins such as SonarQube Scanner, NodeJS, Docker, and Prometheus metrics under `Manage Jenkins → Plugins`.

3. **Global Tool Configuration**:
   - Set up tools like JDK 17, SonarQube Scanner, NodeJS, and Docker under `Manage Jenkins → Global Tool Configuration`.
     
7. ## Pipeline Overview
### Pipeline Stages
1. **Git Checkout**: Clones the source code from GitHub.
2. **SonarQube Analysis**: Performs static code analysis.
3. **Quality Gate**: Ensures code quality standards.
4. **Install NPM Dependencies**: Installs NodeJS packages.
5. **Trivy Security Scan**: Scans the project for vulnerabilities.
6. **Docker Build**: Builds a Docker image for the project.
7. **Push to AWS ECR**: Tags and pushes the Docker image to ECR.
8. **Image Cleanup**: Deletes images from the Jenkins server to save space.

8.### Running Jenkins Pipeline
Create and run the build pipeline in Jenkins. The pipeline will build, analyze, and push the project Docker image to ECR.
Create a Jenkins pipeline by adding the following script:

9.### Build Pipeline
   ```groovy
    pipeline {
    agent any

    environment {
        AWS_REGION     = 'us-east-1'
        ECR_REGISTRY   = '149536457645.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO       = 'app-repo'
        IMAGE_NAME     = "${ECR_REGISTRY}/${ECR_REPO}"
        IMAGE_TAG      = 'latest' // Or use BUILD_NUMBER if preferred
        FULL_IMAGE     = "${IMAGE_NAME}:${IMAGE_TAG}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/PavanKrish2494/PavanKrish2494.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_REPO} ."
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    sh "npm install && npm test"
                }
            }
        }

        stage('Create ECR Repository (if not exists)') {
            steps {
                script {
                    sh """
                        aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} || \
                        aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}
                    """
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Tag and Push Image to ECR') {
            steps {
                script {
                    sh """
                        docker tag ${ECR_REPO}:latest ${FULL_IMAGE}
                        docker push ${FULL_IMAGE}
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh """
                        sed 's|IMAGE_PLACEHOLDER|${FULL_IMAGE}|g' k8s/deployment.yaml > k8s/deployment_temp.yaml
                        kubectl apply -f k8s/deployment_temp.yaml
                        kubectl apply -f k8s/service.yaml
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

