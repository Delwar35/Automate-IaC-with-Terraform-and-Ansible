# Automate-IaC-with-Terraform-and-Ansible

## Task

![image](https://user-images.githubusercontent.com/94615905/149131105-051a326b-8c3b-4d08-a65f-24d9ebb4d31a.png)

## Building Jenkins Server

> To use Jenkins Java needs to be installed
- Step 1: Create an ec2 instance for jenkins
- Step 2: Install Java

```
sudo apt update
sudo apt install openjdk-11-jdk
```
 > `sudo apt search openjdk` can be used to see what JDK are available. The code above installs JDK 11

`java -version` to check the installation 

- Step 3: Install jenkins on ec2 instance

```
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
```
> link to usefull doc to help install jenkins (https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-18-04)

- Set 4: open firewall
  - `sudo ufw allow 8080` 
  - > Jenkins runs on port 8080

- Step 5: open jenkins using your server domain name or IP address
  - `http://your_server_ip_or_domain:8080`
  - If Jenkins is running on ec2 instance `ec2 ip:8080` e.g. `34.242.6.44:8080`

You should see the Unlock Jenkins screen.

![image](https://user-images.githubusercontent.com/94615905/146036477-bd748f36-e9c3-42f8-9810-83b7f9f74f05.png)

- Step 6: Enter Administrator password and then click continue
  - `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` will show the administrator password

- Step 7: Add plugins

![image](https://user-images.githubusercontent.com/94615905/146038193-dbd2fe37-92c0-4a16-ba17-0741d5280342.png)

- Step 8: Create User

![image](https://user-images.githubusercontent.com/94615905/146038704-cfa65f48-4b2a-4a3a-9a8c-44b34b045524.png)

- Step 9: Configure Instance
  - Confirm the preferred URL for your Jenkins instance.

![image](https://user-images.githubusercontent.com/94615905/146039168-22366502-1411-4ddd-a3a4-58949891e3af.png)

- Step 10: Click save and finish
  - You will see a confirmation page confirming that “Jenkins is Ready!”
  
  ![image](https://user-images.githubusercontent.com/94615905/146039410-b5737986-5110-430e-b012-c2000d6c20f2.png)
  
  - Click Start using Jenkins to go to the main Jenkins dashboard and start to use Jenkins
  
  > Jenkis is now all setup and ready to use


## Installing Terrform plugin

![image](https://user-images.githubusercontent.com/94615905/149137652-9299337a-132a-4415-8f61-e99eb6edb570.png)

## Creating Iac using terraform
### Creating VPC using Terraform

```
resource "aws_vpc" "vpc_terraform" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "eng99_delwar_vpc_terraform_jenkins"
    }
}
```

### Creating Internet Gateway

```
resource "aws_internet_gateway" "IG" {
    vpc_id = aws_vpc.vpc_terraform.id
    tags = {
        Name = "eng99_delwar_terraform_IG_jenkins"
    }
}
```

### Creating public subnet using Terraform

```
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc_terraform.id
  availability_zone = "eu-west-1a"
  cidr_block = "10.0.25.0/24"
  tags = {
        Name = "eng99_delwar_public_subnet_terraform_jenkins"
    }
}
```

### Creating private subnet using Terraform

```
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc_terraform.id 
  availability_zone = "eu-west-1a"
  cidr_block = "10.0.26.0/24"
  tags = {
        Name = "eng99_delwar_private_subnet_terraform_jenkins"
    }
}
```

### Create a route table for public subnet

```
resource "aws_route_table" "public_rt_terraform" {
    vpc_id = aws_vpc.vpc_terraform.id
         route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.IG.id
        }
    tags = {
      "Name" = "eng99_delwar_public_rt_terraform_jenkins"
    }
}

# Route Table association to public subnet
resource "aws_route_table_association" "public_rt_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt_terraform.id
    }
```
### Create a route table for private subnet

```
resource "aws_route_table" "private_rt_terraform" {
    vpc_id = aws_vpc.vpc_terraform.id
         route {
            cidr_block = "0.0.0.0/0"
        }
    tags = {
      "Name" = "eng99_delwar_private_rt_terraform"
    }
}

# Route Table association to private subnet

resource "aws_route_table_association" "private_rt_association" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt_terraform.id
    }
```
### Creating app ec2 instance with security groups using Terraform

#### App security group (sg)
```
resource "aws_security_group" "security_group" {
    # engress rules is the outbound rules
    # allow all outbound
    vpc_id = aws_vpc.vpc_terraform.id
    egress {
        from_port = 0
        to_port = 0
        # can use "ALL" instead of "-1" 
        # "-1" and "ALL" can only be used if from_port and to_port is 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
    # ingress rules is the inbound rules

    # allow all to ssh to the machine with port 22
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow the app to run
    ingress {
        from_port = "3000"
        to_port = "3000"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

     tags = {
        Name = "eng99_delwar_terraform_jenkins_app_sg"
    }

} 

```

#### app EC2

```
resource "aws_instance" "app_instance" {
  # add the ami  
  ami =  "ami-07d8796a2b0f8d29c"
  # choose t2
  instance_type = "t2.micro"
  #enable public IP
  associate_public_ip_address = true
  # associating subnet
  subnet_id = aws_subnet.public_subnet.id
  # associating security group
  vpc_security_group_ids = [aws_security_group.security_group.id]
  # add tags
  tags = {
      Name = "eng99_delwar_terraform_jenkins_app"
  }
  
  key_name = "eng99" # ensure that we have key in .ssh file 
}
```
### Creating db ec2 instance with security groups using Terraform
#### Security Group (sg)

```
# creating security groups for db
resource "aws_security_group" "security_group_db" {
    # engress rules is the outbound rules
    # allow all outbound
    vpc_id = aws_vpc.vpc_terraform.id 

    egress {
        from_port = 0
        to_port = 0
        # can use "ALL" instead of "-1" 
        # "-1" and "ALL" can only be used if from_port and to_port is 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
    # ingress rules is the inbound rules

    # allow all to ssh to the machine with port 22
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow the db to run
    ingress {
        from_port = "27017"
        to_port = "27017"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }

    tags = {
        Name = "eng99_delwar_terraform_jenkins_db_sg"
    }
} 
```
#### db EC2

```
# creating a db ec2 instance
resource "aws_instance" "db_instance" {
  # add the ami  
  ami =  "ami-07d8796a2b0f8d29c"
  # choose t2
  instance_type = "t2.micro"
  #enable public IP
  associate_public_ip_address = false
  # associating subnet
  subnet_id = aws_subnet.private_subnet.id
  # associating security group
  vpc_security_group_ids = [aws_security_group.security_group_db.id]
  # add tags
  tags = {
      Name = "eng99_delwar_terraform_jenkins_db"
  }
  
  key_name = "eng99" # ensure that we have key in .ssh file 
}
```

### Creating ansible ec2 instance with security groups using Terraform

```

```

## Running Terraform in jenkins 

- Step 1: install Terraform plugin  (dashboard > manage jenkins > manage plugin > availble)
- Step 2: add AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY (Dashboard > configure system > global properties)
- Step 3: create a new jenkins job
 - > pick pipeline for the job and not freespace
 - Step 4: Configure job
 
  ![image](https://user-images.githubusercontent.com/94615905/149190501-56054086-13f7-4940-b8e2-ead0f3e02789.png)
  ![image](https://user-images.githubusercontent.com/94615905/149190688-86e84faf-ab8d-42df-b0bf-10e517d00fc1.png)
  ![image](https://user-images.githubusercontent.com/94615905/149190779-7549b0fa-2acc-49e7-a763-40528840dc28.png)

### Code in script

```
pipeline {
    agent any
    stages {
        stage ('Checkout'){
            steps {
                sh 'rm -rf Automate-IaC-with-Terraform-and-Ansible'
                sh "git clone https://github.com/Delwar35/Automate-IaC-with-Terraform-and-Ansible.git"
            }
        }
        stage('Apply Terraform'){
            steps{
                dir("Automate-IaC-with-Terraform-and-Ansible"){
                    sh 'terraform init'
                    sh 'terraform apply --auto-approve'
                }
            }
            
        }
        
    }
}
```

## Create webhook

- Open gitbash and cd into .ssh file
- `ssh-keygen -t rsa -b 4096 -C "emailaddress"` e.g ssh-keygen -t rsa -b 4096 -C "bob@hotmail.com"
> this will create a public and private key
- enter a name for the keys
- go to github repo
- click on settings 
- click deploy key
- add key <file> and copy the public key into github

![image](https://user-images.githubusercontent.com/94615905/145449161-09c6b32a-320b-4b7a-9ad4-82ecafdfa0cf.png)
  
#### Adding webjook
  
![image](https://user-images.githubusercontent.com/94615905/145450801-5ba06728-3890-450f-8924-9ee214d20fc3.png)

 url (e.g `http://35.178.35.127:8080/` ) + `github-webhook/`

## Running playbooks on Jenkins
 
### Step 1: Set up ansible
 - Install the ansible pulgin on jenkins
 
 ![image](https://user-images.githubusercontent.com/94615905/149317129-e4dfa537-381a-493b-9df0-e02d1550d816.png)
 
- ssh into jenkins ec2 instance and dowmload ansible in the ec2 instance 
  - install Jenkins command
 ```
 sudo apt-get update -y
 sudo apt-get upgrade -y
 sudo apt-get install software-properties-common 
 
 sudo apt-add-repository ppa:ansible/ansible
 sudo apt-get update
 sudo apt-get install ansible
 ```
 - Go to global Tool Configureation and add ansible and the path for it in the jenkins ec2
 
 ![image](https://user-images.githubusercontent.com/94615905/149323304-bd6103b3-4a45-4e81-a6f8-a42f3bfbf9e1.png)

 > This will allow you to use ansible in jenkins jobs
 > The path can be found by using the command `which ansible`
 > ![image](https://user-images.githubusercontent.com/94615905/149323663-373cb10d-aa4f-4867-8cb2-be92d7ab7822.png)
 
 
### Step 2 create playbook to install mongodb and create a host file
 - create a .yml file (`sudo nano install_mongodb.yml`) and add the code below in 
 ```
 # Installing mongo in db VM
---
# host name
- hosts: db
  gather_facts: yes

# gather facts for installation

# we need admin access
  become: true

# The actual task is to install mongodb in db VM

  tasks:
  - name:
    shell: |
      sudo apt-get update -y
      sudo apt-get upgrade -y
      
  - name: Installing mongodb in db VM
    apt: pkg=mongodb state=present

  - name: restarting db and chnaging conf file
    shell: |
      rm -rf /etc/mongod.conf
      cp ./mongod.conf /etc/mongod.conf
      sudo systemctl restart mongodb
      sudo systemctl enable mongodb
    become_user: root
 
 ```
- create a host file with the extemsion .inv `sudo nano hosts.inv`
 ```
 [db]
ec2-instance ansible_host=54.72.204.195 ansible_user=ubuntu

[app]
ec2-instance ansible_host=34.247.167.192 ansible_user=ubuntu
```
### Step 3: create jenkins job to run db playbook

![image](https://user-images.githubusercontent.com/94615905/149360657-57ffd914-a6fe-407f-be8f-51e82259c5ad.png)
![image](https://user-images.githubusercontent.com/94615905/149360782-2bee0362-3878-4808-8358-a90865578520.png)

```
pipeline {
    agent any
    stages {
        stage ('Get Filles'){
            steps {
                sh 'rm -rf Automate-IaC-with-Terraform-and-Ansible'
                sh "git clone https://github.com/Delwar35/Automate-IaC-with-Terraform-and-Ansible.git"
            }
        }
        stage('Execute Ansible plaaybook'){
            steps{
                dir("Automate-IaC-with-Terraform-and-Ansible"){
                    ansiblePlaybook credentialsId: 'ff2dd3cc-5820-4ab0-b1c4-64b39cc42ee7', disableHostKeyChecking: true, installation: 'Ansible', inventory: 'hosts.inv', playbook: 'install_mongodb.yml'
                }
            }
            
        }
        
    }
} 
```
- Inside Pipline Syntax

![image](https://user-images.githubusercontent.com/94615905/149362916-22656fa2-83ab-48ff-935e-9afff2a84efa.png)
![image](https://user-images.githubusercontent.com/94615905/149362686-7f740514-9bb4-40c0-aba8-1d2a5cf5d1f5.png)



> ubuntu is the eng99.pem file with user set to ubuntu
 

### Step 4: Create playbooks for App ec2 instance
- Nginx playbook

 ```
 # This file is to configure and install nginx in web agent
---
# which host do we need to install nginx in
- hosts: app
  gather_facts: true

# what facts do we want to see while installing

# do we need admin access? yes
  become: true

# what task do we want to perform in this yml file
  tasks:
  - name: Install Nginx in web Agent Node
    apt: pkg=nginx state=present
    become_user: root

  - name: Setting reverse proxy
    shell: |
      sudo rm -rf /etc/nginx/sites-available/default
      cp ./awsFileTransfer/default /etc/nginx/sites-available/default
    become_user: root

  - name: Restart Ngnix
    shell: |
      sudo systemctl restart nginx
    become_user: root
 
 ```
 
- Nodejs playbook
 
 ```
 # which host do we need to install nginx in
- hosts: app
  gather_facts: true

# what facts do we want to see while installing

# do we need admin access? yes
  become: true

# what task do we want to perform in this yml file
  tasks:

  - name: Install Nodejs in web Agent Node
    shell: |
      curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - && sudo apt-get install nodejs -y

  - name: Install npm and pm2
    shell: |
      sudo apt install npm -y
      sudo npm install pm2 -g

  - name: env variable
    shell: |
      echo 'export DB_HOST="mongodb://192.168.33.11:27017/posts"' >> .bashrc
    become_user: root


  - name: Seed and run app
    shell: |
      cd awsFileTransfer/
      cd app/
      npm install
      node seeds/seed.js
      #pm2 kill
      #pm2 start app.js

    become_user: root
 ```
### Step 5: Create job to run app playbooks 
 
The Job to run the playbook is the same as the job to run the playbook for the db ec2 instance but with a different script.
 
 - Script for job
 
 ```
 pipeline {
    agent any
    stages {
        stage ('Get Filles'){
            steps {
                sh 'rm -rf Automate-IaC-with-Terraform-and-Ansible'
                sh "git clone https://github.com/Delwar35/Automate-IaC-with-Terraform-and-Ansible.git"
            }
        }
        stage('Execute Ansible plaaybook'){
            steps{
                dir("Automate-IaC-with-Terraform-and-Ansible"){
                    ansiblePlaybook credentialsId: 'ff2dd3cc-5820-4ab0-b1c4-64b39cc42ee7', disableHostKeyChecking: true, installation: 'Ansible', inventory: 'hosts.inv', playbook: 'install_nginx.yml'
                    ansiblePlaybook credentialsId: 'ff2dd3cc-5820-4ab0-b1c4-64b39cc42ee7', disableHostKeyChecking: true, installation: 'Ansible', inventory: 'hosts.inv', playbook: 'install_nodejs.yml'
                }
            }
            
        }
        
    }
} 
 ```

 
 

 




