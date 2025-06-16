To **fully delete your CI/CD PoC setup** but **keep the code in GitHub**, follow this structured teardown:

---

### **✅ Step 1: Disable GitHub Actions (but keep code)**

You can disable the automation in two ways:

#### **🔹 Option A: Rename the workflow file**

Rename the file .github/workflows/deploy.yml → .github/workflows/deploy.yml.disabled

> This prevents GitHub from recognizing it as a workflow.

#### **🔹 Option B: Disable Actions for the whole repo**

1. Go to **GitHub repo → Settings → Actions** 
2. Under **“Actions permissions”**, choose **Disable Actions for this repository**

---

### **✅ Step 2: Delete the AWS CloudFormation Stack**

This will delete **all resources** created via the stack, such as:

- ECS Cluster + Services  
- ALB + Target Groups   
- IAM roles  
- ECR repos (unless manually created) 
- VPC/Subnets (if included in the template)  

#### **Command:**

```
aws cloudformation delete-stack --stack-name cicd-poc-stack --region us-east-1
```

You can also monitor progress in AWS Console → CloudFormation → Stacks → cicd-poc-stack → Events.

---

### **✅ Step 3: Confirm ECS/ECR Resources Are Deleted**

If any resources were manually created and are **not in the CloudFormation template**, delete them manually:

#### **ECS:**

```
aws ecs delete-cluster --cluster cicd-poc-cluster --region us-east-1
```

> ⚠️ Only do this if you’re **sure** it’s not part of an active environment.

#### **ECR (if needed):**

List repositories:
```
aws ecr describe-repositories --region us-east-1
```

Then delete:
```
aws ecr delete-repository --repository-name your-repo-name --force --region us-east-1
```

---

### **✅ Step 4: (Optional) Remove EC2 instance (if not already removed)**

If the EC2 instance wasn’t created by CloudFormation, delete it via:
```
aws ec2 terminate-instances --instance-ids i-xxxxxxxxxxxx --region us-east-1
```

---
### **✅ Done**

