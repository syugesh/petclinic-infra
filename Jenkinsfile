pipeline {
  agent any

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Choose what Terraform should do.')
    string(name: 'KEY_NAME', defaultValue: 'petclinic-key', description: 'Existing AWS EC2 key pair name.')
    string(name: 'SSH_ALLOWED_CIDR', defaultValue: 'YOUR_PUBLIC_IP/32', description: 'Your public IP in CIDR format, for example 203.0.113.10/32.')
  }

  environment {
    AWS_REGION = 'us-east-1'
  }

  stages {
    stage('Terraform Format') {
      steps {
        sh 'terraform -chdir=terraform fmt -check -recursive'
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform -chdir=terraform init'
      }
    }

    stage('Terraform Validate') {
      steps {
        sh 'terraform -chdir=terraform validate'
      }
    }

    stage('Terraform Plan') {
      when {
        expression { params.ACTION != 'destroy' }
      }
      steps {
        withCredentials([string(credentialsId: 'petclinic-db-password', variable: 'TF_VAR_db_password')]) {
          sh '''
            terraform -chdir=terraform plan \
              -var "key_name=${KEY_NAME}" \
              -var "ssh_allowed_cidr=${SSH_ALLOWED_CIDR}" \
              -out=tfplan
          '''
        }
      }
    }

    stage('Terraform Apply') {
      when {
        expression { params.ACTION == 'apply' }
      }
      steps {
        input 'Apply infrastructure changes?'
        withCredentials([
          string(credentialsId: 'petclinic-db-password', variable: 'TF_VAR_db_password'),
          sshUserPrivateKey(credentialsId: 'petclinic-app-ssh-key', keyFileVariable: 'APP_SSH_KEY')
        ]) {
          sh '''
            terraform -chdir=terraform apply -auto-approve tfplan

            APP_IP=$(terraform -chdir=terraform output -raw app_public_ip)
            cat > ansible/inventory.ini <<EOF
[app]
${APP_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${APP_SSH_KEY} ansible_python_interpreter=/usr/bin/python3
EOF

            ansible-playbook -i ansible/inventory.ini ansible/app-server.yml
          '''
        }
      }
    }

    stage('Terraform Destroy') {
      when {
        expression { params.ACTION == 'destroy' }
      }
      steps {
        input 'Destroy all infrastructure?'
        withCredentials([string(credentialsId: 'petclinic-db-password', variable: 'TF_VAR_db_password')]) {
          sh '''
            terraform -chdir=terraform destroy -auto-approve \
              -var "key_name=${KEY_NAME}" \
              -var "ssh_allowed_cidr=${SSH_ALLOWED_CIDR}"
          '''
        }
      }
    }
  }
}

