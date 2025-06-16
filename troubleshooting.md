Excellent work — you’re very close! Here’s what we’ve verified:
---

### **✅ What’s Working:**
- Your **EC2 NGINX instance is running** and accessible via public IP: 52.55.55.27
    
- **NGINX is actively running**
    
- **Security group is open on port 80** to the world (0.0.0.0/0)
    
- **Your NGINX config proxies** /activity/ and /attendance/ to your ALB
    
- Curl to /activity returns a **301 redirect** (normal if you’re hitting /activity instead of /activity/)
    
---

### **🧪 Now Test in Browser**
  
Visit:
- [http://52.55.55.27/activity/](http://52.55.55.27/activity/)
    
- [http://52.55.55.27/attendance/](http://52.55.55.27/attendance/)
    
  
If everything is working correctly, you should see:
```
Hello from Activity App
```
and
```
Hello from Attendance App
```
If not, then let’s check ALB and ECS…

---

## **🛠️ Diagnostic If /activity/ or /attendance/ Fail**
  
### **✅ 1. Try Curl From EC2 Itself to ALB**
```
curl http://cicd-poc-alb-760003064.us-east-1.elb.amazonaws.com/activity/
curl http://cicd-poc-alb-760003064.us-east-1.elb.amazonaws.com/attendance/
```
This tests whether the ALB routes to ECS services correctly.
  
If you get:
- Hello from ...: great, ECS is working.
    
- Anything else (5xx, timeout): ECS task or Target Group may be failing.
    
---

### **✅ 2. Check ECS Target Group Health**
  
Run:
```
aws elbv2 describe-target-health \
  --target-group-arn <replace-with-activity-target-group-arn> \
  --region us-east-1
```
And same for attendance.
  
Replace the ARN with the actual TargetGroupArn for each app — you can find them by:
```
aws elbv2 describe-target-groups --region us-east-1 \
  --names ActivityTargetGroup AttendanceTargetGroup
```
---

### **✅ 3. Check ECS Task Logs (if needed)**
  
If ECS health checks are failing, review logs:
```
aws logs describe-log-groups --region us-east-1
aws logs describe-log-streams --log-group-name /ecs/activity --region us-east-1
aws logs get-log-events \
  --log-group-name /ecs/activity \
  --log-stream-name <log-stream-name> \
  --region us-east-1
```
---

## **✅ Optional: DNS Setup**
  
Once this works, you can point a domain (example.com) to your EC2 public IP using GoDaddy or Route53, then requests to:
```
http://example.com/activity/
```
Will be routed properly by NGINX → ALB → ECS → app.

---

Thanks, that narrows it down. A 503 Service Temporarily Unavailable from **NGINX** via the **ALB** usually means:
  
> 🔥 **The ECS tasks (containers) are not healthy or not running**, so the ALB has no targets to forward traffic to.
  
Let’s fix this step by step.

---
## **✅ 1. Confirm ECS Services and Task Status**
  
Run the following to list ECS services and tasks:
```
aws ecs list-clusters --region us-east-1
```
You’ll get your cluster name, e.g., cicd-poc-cluster.
  
Then:
```
aws ecs list-services \
  --cluster cicd-poc-cluster \
  --region us-east-1
```
Check if ActivityService and AttendanceService are listed.
  
Then check tasks:
```
aws ecs list-tasks \
  --cluster cicd-poc-cluster \
  --service-name ActivityService \
  --region us-east-1
```
If no task is listed, the service couldn’t start it. If a task is shown, get its details:
```
aws ecs describe-tasks \
  --cluster cicd-poc-cluster \
  --tasks <task-arn> \
  --region us-east-1
```
---
## **✅ 2. Check Target Group Health**
  
This is critical. Let’s verify whether the ALB sees your ECS tasks as healthy:
  
### **First get your Target Group ARNs:**
```
aws elbv2 describe-target-groups \
  --region us-east-1 \
  --names ActivityTargetGroup AttendanceTargetGroup
```
### **Then check their health:**
```
aws elbv2 describe-target-health \
  --target-group-arn <activity-target-group-arn> \
  --region us-east-1
```
If you see:
```
"TargetHealth": {
  "State": "unhealthy",
  ...
}
```
→ ALB sees the task but it’s **unhealthy** (often due to bad healthCheckPath, port issue, or container crash).

---
## **✅ 3. Check Application Logs from ECS**
  
Your containers should output logs to CloudWatch. List log groups:
```
aws logs describe-log-groups --region us-east-1
```
You should see something like:
- /ecs/activity
    
- /ecs/attendance
    
  
Then get logs:
```
aws logs describe-log-streams \
  --log-group-name /ecs/activity \
  --region us-east-1
aws logs get-log-events \
  --log-group-name /ecs/activity \
  --log-stream-name <your-log-stream-name> \
  --region us-east-1
```
---
## **🛠️ Common Causes & Fixes**
|**Cause**|**Fix**|
|---|---|
|Container failed to start|Check logs in CloudWatch|
|Health check path wrong|Make sure /activity app responds to /activity/health or /|
|Port mismatch|Dockerfile EXPOSE port must match ECS container port and TG port|
|ALB Target Group not attached|Confirm in CloudFormation output or ALB UI|
---
### **🔍 Want to Quickly Check with ECS Console?**
1. Go to AWS Console → **ECS**
    
2. Click cicd-poc-cluster
    
3. Click **ActivityService**
    
4. See if there’s a running task
    
5. Click on task → **Logs** tab
    
---

```
An error occurred (ServiceNotFoundException) when calling the ListTasks operation: Service not found.
```
is happening because you’re using the **logical name ActivityService**, but AWS ECS requires the **full service name or ARN**, which includes the **CloudFormation stack prefix**.

---

### **✅ Step-by-Step Fix:**
  
You already listed the **actual service names**:
```
"serviceArns": [
  "arn:aws:ecs:us-east-1:538768644931:service/cicd-poc-cluster/cicd-poc-stack-AttendanceService-ZO4HoydBrwHN",
  "arn:aws:ecs:us-east-1:538768644931:service/cicd-poc-cluster/cicd-poc-stack-ActivityService-BmDH0LSWHx1w"
]
```
Use the **full service name** when calling list-tasks.

---

### **🔄 Correct Command:**
```
aws ecs list-tasks \
  --cluster cicd-poc-cluster \
  --service-name cicd-poc-stack-ActivityService-BmDH0LSWHx1w \
  --region us-east-1
```
And for attendance:
```
aws ecs list-tasks \
  --cluster cicd-poc-cluster \
  --service-name cicd-poc-stack-AttendanceService-ZO4HoydBrwHN \
  --region us-east-1
```
---

### **✅ If Tasks Exist**
  
Then run:
```
aws ecs describe-tasks \
  --cluster cicd-poc-cluster \
  --tasks <task-arn> \
  --region us-east-1
```
Look for:
- lastStatus: should be RUNNING
    
- healthStatus: should be HEALTHY
    
- stoppedReason: should be empty
    
---


### **✅ Likely Root Causes**
1. **No Docker image available in ECR**
    
    - ECS service has no container to launch.
        
    
2. **Task definition references a non-existent or unauthorized ECR image**
    
    - For example, image: 538768644931.dkr.ecr.us-east-1.amazonaws.com/activity:latest may not exist.
        
    
3. **Security group or subnet misconfiguration**
    
    - But since you’re using Fargate with public subnets, less likely at this point.
        
    
4. **CloudFormation created ECS services before ECR image was pushed**
    
    - Common in CI/CD setups. Services are created, but fail to start tasks due to missing image.
          
---

### **🧪 To Verify Immediately:**
  
Run the following to check whether the image exists in ECR:
```
aws ecr list-images \
  --repository-name activity \
  --region us-east-1
```
And for attendance:
```
aws ecr list-images \
  --repository-name attendance \
  --region us-east-1
```
If both return empty lists, your services have **nothing to run**.

---

### **✅ What To Do Next**
  
#### **🛠 Option 1: Manually Build and Push Docker Images**
  
If you haven’t pushed your Docker images yet, do this:
```
# Authenticate with ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS \
  --password-stdin 538768644931.dkr.ecr.us-east-1.amazonaws.com
```
Then for **Activity app**:
```
cd activity
docker build -t activity .
docker tag activity:latest 538768644931.dkr.ecr.us-east-1.amazonaws.com/activity:latest
docker push 538768644931.dkr.ecr.us-east-1.amazonaws.com/activity:latest
```
And for **Attendance app**:
```
cd attendance
docker build -t attendance .
docker tag attendance:latest 538768644931.dkr.ecr.us-east-1.amazonaws.com/attendance:latest
docker push 538768644931.dkr.ecr.us-east-1.amazonaws.com/attendance:latest
```

---

### **🔁 Then, Redeploy ECS Services**
  
After pushing the Docker images, redeploy each service to trigger task creation:
```
aws ecs update-service \
  --cluster cicd-poc-cluster \
  --service cicd-poc-stack-ActivityService-BmDH0LSWHx1w \
  --force-new-deployment \
  --region us-east-1
aws ecs update-service \
  --cluster cicd-poc-cluster \
  --service cicd-poc-stack-AttendanceService-ZO4HoydBrwHN \
  --force-new-deployment \
  --region us-east-1
```
This will cause ECS to re-evaluate the service and launch tasks now that the image is available.

---

## **🔹** 
## **your-ecr-repo-name**
##  **(ECR Repository Name)**
  
This is the name of your **Amazon ECR (Elastic Container Registry)** repository where Docker images are pushed.
  
### **🔍 Find it via AWS CLI:**
```
aws ecr describe-repositories --region us-east-1 \
  --query 'repositories[*].repositoryName' --output text
```
This will output:
```
activity-app attendance-app
```
So in your GitHub Actions workflow:
```
ECR_REPOSITORY: activity-app  # or attendance-app
```
Or, go to **AWS Console > ECR > Repositories** to see the names.

---

## **🔹** 
## **ActivityService-XXXX**
##  **(Full ECS Service Name)**
  
You already listed your ECS services:
```
aws ecs list-services \
  --cluster cicd-poc-cluster --region us-east-1
```
You got:
```
arn:aws:ecs:us-east-1:538768644931:service/cicd-poc-cluster/cicd-poc-stack-AttendanceService-ZO4HoydBrwHN
arn:aws:ecs:us-east-1:538768644931:service/cicd-poc-cluster/cicd-poc-stack-ActivityService-BmDH0LSWHx1w
```
So for:
- **Activity Service** ➤ cicd-poc-stack-ActivityService-BmDH0LSWHx1w
    
- **Attendance Service** ➤ cicd-poc-stack-AttendanceService-ZO4HoydBrwHN
    
  
In GitHub Actions:
```
aws ecs update-service \
  --cluster cicd-poc-cluster \
  --service cicd-poc-stack-ActivityService-BmDH0LSWHx1w \
  --force-new-deployment \
  --region us-east-1
```
---


    
