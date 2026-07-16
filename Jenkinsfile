pipeline {
  agent any

  options {
    disableConcurrentBuilds()
    timestamps()
  }

  parameters {
    choice(
      name: 'ACTION',
      choices: ['plan', 'apply', 'destroy'],
      description: 'Choose what Terraform should do.'
    )

    string(
      name: 'KEY_NAME',
      defaultValue: 'petclinic-key',
      description: 'Existing AWS EC2 key pair name.'
    )

    string(
      name: 'SSH_ALLOWED_CIDR',
      defaultValue: 'YOUR_PUBLIC_IP/32',
      description: 'Jenkins EC2 public IP in CIDR format, for example 13.218.98.146/32.'
    )
  }

  environment {
    AWS_REGION = 'us-east-1'
  }

  stages {
    stage('Validate Parameters') {
      steps {
        sh '''
          set -e

          if [ -z "${KEY_NAME}" ]; then
            echo "ERROR: KEY_NAME cannot be empty."
            exit 1
          fi

          if [ "${SSH_ALLOWED_CIDR}" = "YOUR_PUBLIC_IP/32" ]; then
            echo "ERROR: Replace YOUR_PUBLIC_IP/32 with the Jenkins EC2 public IP."
            exit 1
          fi

          echo "Terraform action: ${ACTION}"
          echo "EC2 key pair: ${KEY_NAME}"
          echo "SSH allowed from: ${SSH_ALLOWED_CIDR}"
        '''
      }
    }

    stage('Terraform Format') {
      steps {
        sh '''
          terraform -chdir=terraform fmt -check -recursive
        '''
      }
    }

    stage('Terraform Init') {
      steps {
        sh '''
          terraform -chdir=terraform init -input=false
        '''
      }
    }

    stage('Terraform Validate') {
      steps {
        sh '''
          terraform -chdir=terraform validate
        '''
      }
    }

    stage('Terraform Plan') {
      when {
        expression {
          params.ACTION != 'destroy'
        }
      }

      steps {
        withCredentials([
          string(
            credentialsId: 'petclinic-db-password',
            variable: 'TF_VAR_db_password'
          )
        ]) {
          sh '''
            terraform -chdir=terraform plan \
              -input=false \
              -var "key_name=${KEY_NAME}" \
              -var "ssh_allowed_cidr=${SSH_ALLOWED_CIDR}" \
              -out=tfplan
          '''
        }
      }
    }

    stage('Terraform Apply') {
      when {
        expression {
          params.ACTION == 'apply'
        }
      }

      steps {
        input message: 'Apply infrastructure changes?', ok: 'Proceed'

        withCredentials([
          string(
            credentialsId: 'petclinic-db-password',
            variable: 'TF_VAR_db_password'
          ),

          sshUserPrivateKey(
            credentialsId: 'petclinic-app-ssh-key',
            keyFileVariable: 'APP_SSH_KEY',
            usernameVariable: 'APP_SSH_USER'
          )
        ]) {
          sh '''
            set -e

            echo "Applying Terraform plan..."

            terraform -chdir=terraform apply \
              -input=false \
              -auto-approve \
              tfplan

            APP_IP=$(terraform -chdir=terraform output -raw app_public_ip)

            if [ -z "${APP_IP}" ]; then
              echo "ERROR: Terraform did not return the application EC2 public IP."
              exit 1
            fi

            echo "Application EC2 public IP: ${APP_IP}"

            # Prepare Jenkins SSH directory
            mkdir -p "${HOME}/.ssh"
            chmod 700 "${HOME}/.ssh"
            touch "${HOME}/.ssh/known_hosts"
            chmod 600 "${HOME}/.ssh/known_hosts"

            # Remove any old fingerprint for the same IP
            ssh-keygen \
              -R "${APP_IP}" \
              -f "${HOME}/.ssh/known_hosts" || true

            echo "Waiting for the new EC2 instance SSH service..."

            HOST_KEY_FOUND=false

            for attempt in $(seq 1 30); do
              echo "Host-key check attempt ${attempt}/30"

              if ssh-keyscan \
                  -T 5 \
                  -H "${APP_IP}" \
                  >> "${HOME}/.ssh/known_hosts" 2>/dev/null; then

                HOST_KEY_FOUND=true
                echo "SSH host key received."
                break
              fi

              sleep 10
            done

            if [ "${HOST_KEY_FOUND}" != "true" ]; then
              echo "ERROR: Could not obtain the SSH host key from ${APP_IP}."
              exit 1
            fi

            chmod 600 "${HOME}/.ssh/known_hosts"
            chmod 600 "${APP_SSH_KEY}"

            echo "Waiting for SSH authentication..."

            SSH_READY=false

            for attempt in $(seq 1 30); do
              echo "SSH authentication attempt ${attempt}/30"

              if ssh \
                  -i "${APP_SSH_KEY}" \
                  -o BatchMode=yes \
                  -o ConnectTimeout=10 \
                  -o StrictHostKeyChecking=yes \
                  "${APP_SSH_USER}@${APP_IP}" \
                  "echo SSH connection successful"; then

                SSH_READY=true
                break
              fi

              sleep 10
            done

            if [ "${SSH_READY}" != "true" ]; then
              echo "ERROR: Jenkins could not authenticate to ${APP_IP}."
              exit 1
            fi

            echo "Creating Ansible inventory..."

            cat > ansible/inventory.ini <<EOF
[app]
${APP_IP} ansible_user=${APP_SSH_USER} ansible_ssh_private_key_file=${APP_SSH_KEY} ansible_python_interpreter=/usr/bin/python3
EOF

            echo "Checking Ansible connectivity..."

            ansible \
              all \
              -i ansible/inventory.ini \
              -m ping

            echo "Running Ansible playbook..."

            ansible-playbook \
              -i ansible/inventory.ini \
              ansible/app-server.yml
          '''
        }
      }
    }

    stage('Terraform Destroy') {
      when {
        expression {
          params.ACTION == 'destroy'
        }
      }

      steps {
        input message: 'Destroy all infrastructure?', ok: 'Destroy'

        withCredentials([
          string(
            credentialsId: 'petclinic-db-password',
            variable: 'TF_VAR_db_password'
          )
        ]) {
          sh '''
            terraform -chdir=terraform destroy \
              -input=false \
              -auto-approve \
              -var "key_name=${KEY_NAME}" \
              -var "ssh_allowed_cidr=${SSH_ALLOWED_CIDR}"
          '''
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed successfully.'
    }

    failure {
      echo 'Pipeline failed. Check the failed stage in Console Output.'
    }
  }
}
