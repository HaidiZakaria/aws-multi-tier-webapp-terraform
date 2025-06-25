# 🏗️ AWS Multi-Tier Web Application using Terraform

This project demonstrates the Infrastructure as Code (IaC) deployment of a **highly available multi-tier web application** on AWS using **Terraform**.

---

## 📐 Architecture Overview

![AWS architecture diagram](https://github.com/user-attachments/assets/00119c9c-cbaa-477e-84bc-30b85bc9716e)

---

User → ALB → EC2 (Private Subnet) → RDS MySQL
↑
Bastion Host (Public)



![Architecture Diagram](./architecture.png)

---

## 🚀 What This Project Includes

- ✅ VPC with public/private subnets in 2 AZs
- ✅ Bastion Host for private SSH access
- ✅ Application Load Balancer (ALB)
- ✅ Auto Scaling Group & Launch Template
- ✅ Apache Web Server setup
- ✅ RDS MySQL Database (Private Subnet)
- ✅ Security Groups and Route Tables
- ✅ Written in Terraform and tested on AL2023

---

## 🛠️ Tech Stack

- **Terraform** (IaC)
- **AWS** (EC2, ASG, ALB, RDS, VPC)
- **Amazon Linux 2023**
- **MySQL Client & Apache**

---

## 📂 Project Structure

| File               | Purpose                              |
|--------------------|--------------------------------------|
| `main.tf`          | Main infrastructure definition       |
| `variables.tf`     | Input variable definitions           |
| `outputs.tf`       | Outputs like ALB DNS, RDS endpoint   |
| `terraform.tfvars` | Custom variable values               |
| `bastion_key.pub`  | SSH public key for EC2 instances     |
| `README.md`        | This file                            |

> 🔐 **Do not upload `bastion_key` (private key) to GitHub!**

---

## ⚙️ Usage

### 1. Initialize Terraform

terraform init

2. Preview the Plan

terraform plan

3. Apply the Configuration

terraform apply

4. Get Outputs

terraform output

🔐 Accessing the Web Tier via Bastion

SSH into Bastion:

ssh -i bastion_key ec2-user@<bastion-public-ip>

Then jump into the private EC2:
ssh -i bastion_key ec2-user@<private-ec2-ip>

🌐 Access the Web Application

http://<alb_dns>

You should see:

Hello from Auto Scaling Web Server!

🧪 Connect to RDS
From inside the private EC2:
mysql -h <rds-endpoint> -u admin -p
Enter password: (system given or custom password)

🧠 Lessons Learned:

- Infrastructure-as-Code best practices

- Secure networking with public/private subnets

- Load Balancing and Auto Scaling

- Bastion SSH hopping & remote RDS access

- Terraform modular and layered design



📌 Author
Haidi Zakaria
💻 Passionate about Cloud, DevOps, and Terraform

📜 License
MIT License






