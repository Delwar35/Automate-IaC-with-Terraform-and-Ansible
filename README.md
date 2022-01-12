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
