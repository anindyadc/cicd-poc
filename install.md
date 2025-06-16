## **✅ GOAL**
  
You want a **GitHub Actions CI/CD pipeline** that:
1. **Builds Docker images** for both activity and attendance.
    
2. **Pushes them** to their respective ECR repos.
    
3. **Triggers ECS deployments** for both services.
    
---

## **📁 Assumed GitHub Repo Structure**
```
.
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

---

## **🔐 Set These GitHub Secrets**
  
In your repo, go to **Settings → Secrets and variables → Actions**, then **add these**:
|**Secret Name**|**Description**|
|---|---|
|AWS_ACCESS_KEY_ID|IAM user’s access key|
|AWS_SECRET_ACCESS_KEY|IAM user’s secret key|
|AWS_REGION|us-east-1|
|ECR_ACTIVITY_REPO|e.g. activity-app|
|ECR_ATTENDANCE_REPO|e.g. attendance-app|
|ECS_CLUSTER_NAME|cicd-poc-cluster|
|ACTIVITY_SERVICE_NAME|e.g. cicd-poc-stack-ActivityService-BmDH0LSWHx1w|
|ATTENDANCE_SERVICE_NAME|e.g. cicd-poc-stack-AttendanceService-ZO4HoydBrwHN|
|AWS_ACCOUNT_ID|Your AWS account ID (12-digit)|

---

## **🛠️ GitHub Actions Workflow:** 
## **.github/workflows/deploy.yml**
```
name: Deploy to ECS
on:
  push:
    branches:
      - prod
env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_ACTIVITY_REPO: ${{ secrets.ECR_ACTIVITY_REPO }}
  ECR_ATTENDANCE_REPO: ${{ secrets.ECR_ATTENDANCE_REPO }}
  ECS_CLUSTER: ${{ secrets.ECS_CLUSTER_NAME }}
  ACTIVITY_SERVICE: ${{ secrets.ACTIVITY_SERVICE_NAME }}
  ATTENDANCE_SERVICE: ${{ secrets.ATTENDANCE_SERVICE_NAME }}
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
jobs:
  deploy:
    name: Build & Deploy to ECS
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}
    - name: Login to Amazon ECR
      run: |
        aws ecr get-login-password --region $AWS_REGION | \
        docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    - name: Build and push ACTIVITY image
      run: |
        docker build -t $ECR_ACTIVITY_REPO ./activity
        docker tag $ECR_ACTIVITY_REPO:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_ACTIVITY_REPO:latest
        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_ACTIVITY_REPO:latest
    - name: Build and push ATTENDANCE image
      run: |
        docker build -t $ECR_ATTENDANCE_REPO ./attendance
        docker tag $ECR_ATTENDANCE_REPO:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_ATTENDANCE_REPO:latest
        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_ATTENDANCE_REPO:latest
    - name: Deploy Activity to ECS
      run: |
        aws ecs update-service \
          --cluster $ECS_CLUSTER \
          --service $ACTIVITY_SERVICE \
          --force-new-deployment \
          --region $AWS_REGION
    - name: Deploy Attendance to ECS
      run: |
        aws ecs update-service \
          --cluster $ECS_CLUSTER \
          --service $ATTENDANCE_SERVICE \
          --force-new-deployment \
          --region $AWS_REGION
```

---

## **✅ Steps to Proceed**
1. ✅ Push this deploy.yml to .github/workflows/ in your repo.
    
2. ✅ Ensure all the secrets above are configured.
    
3. ✅ Push a commit to the prod branch.
    
4. ✅ Watch the **Actions tab** on GitHub for the workflow to build & deploy both apps.
    
---
