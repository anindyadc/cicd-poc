# README File
### **📌** 
### **Flow Diagram (CI/CD + Deployment Flow)**
  
#### **🧠** 
#### **Code to Deployment Flow**
```
GitHub (Repo: cicd-poc)
     |
     | Push to "main"/"prod"
     ↓
GitHub Actions Workflow
     |
     | Runs CI: Build Docker images for
     |  - activity
     |  - attendance
     ↓
Pushes images to ECR
     |
     ↓
Triggers AWS CodePipeline (or manually invokes CodeBuild)
     |
     ↓
CodeBuild deploys ECS Fargate Services via CloudFormation (Stack)
     |
     ↓
ECS Fargate (2 services)
  ├── ActivityService (containerPort: 3000)
  └── AttendanceService (containerPort: 3000)
     |
     ↓
Application Load Balancer (ALB)
  ├── Rule: `/activity/*` → ActivityService Target Group
  └── Rule: `/attendance/*` → AttendanceService Target Group
     |
     ↓
User accesses via:
http://<ALB-DNS>/activity/  
http://<ALB-DNS>/attendance/
```
---

### **🔁** 
### **Simplified Resource Flow (Infra)**
```
GitHub ➝ GitHub Actions ➝ ECR
         ↓
     CodeBuild (via CodePipeline or manually)
         ↓
   CloudFormation Stack:
     ├─ VPC + Subnets
     ├─ ALB (Listener rules for /activity and /attendance)
     ├─ ECS Cluster
     ├─ ECS Fargate Services x2 (1 Task each)
     ├─ Target Groups (health check path = /activity or /attendance)
```

---

## Repository Structure
```
cicd-poc/
├── .github
│   └── workflows
│       └── deploy.yml
├── activity
│   ├── app.js
│   └── Dockerfile
├── attendance
│   ├── app.js
│   └── Dockerfile
├── buildspec.yml (optional if not using CodeBuild)
└── README.md
```
## Architecture Overview
```
User Browser
     │
     ▼
http://example.com/activity ─┐
http://example.com/attendance│
                             ▼
                 EC2 NGINX (proxy)
                             ▼
              ALB (path-based routing)
              ├── /activity    → ECS: activity-task
              └── /attendance  → ECS: attendance-task
```
## Create Stack
```
aws cloudformation create-stack \
  --stack-name cicd-poc-stack \
  --template-body file://cicd-poc-vpc.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```
The EC2 Key Pair my-key-pair exists in us-east-1
```
aws ec2 describe-key-pairs --region us-east-1
```
Get AMI
```
aws ec2 describe-images --owners amazon \
  --filters 'Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2' \
  --query 'Images[*].[ImageId,CreationDate]' \
  --region us-east-1 \
  --output text | sort -k2 -r | head -n 1
```
## Delete Stack
```
aws cloudformation delete-stack --stack-name cicd-poc-stack --region us-east-1
```
## Get the Public IP or DNS of the NGINX EC2 Instance
```
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=NGINXInstance" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --region us-east-1 \
  --output text
```
## Get All Instances with Public IPs
```
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,Tags]" \
  --region us-east-1 \
  --output table
```

⸻

## **🔐 Set These GitHub Secrets**

In your repo, go to **Settings → Secrets and variables → Actions**, then **add these**:

| **Secret Name**         | **Description**                                    |
| ----------------------- | -------------------------------------------------- |
| AWS_ACCESS_KEY_ID       | IAM user’s access key                              |
| AWS_SECRET_ACCESS_KEY   | IAM user’s secret key                              |
| AWS_REGION              | us-east-1                                          |
| ECR_ACTIVITY_REPO       | e.g. activity-app                                  |
| ECR_ATTENDANCE_REPO     | e.g. attendance-app                                |
| ECS_CLUSTER_NAME        | cicd-poc-cluster                                   |
| ACTIVITY_SERVICE_NAME   | e.g. cicd-poc-stack-ActivityService-BmDH0LSWHx1w   |
| ATTENDANCE_SERVICE_NAME | e.g. cicd-poc-stack-AttendanceService-ZO4HoydBrwHN |
| AWS_ACCOUNT_ID          | Your AWS account ID (12-digit)                     |

⸻