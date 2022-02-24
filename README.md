# batch-job-template

Template for ad-hoc jobs to be run in a Docker container, possibly in [AWS Batch](https://aws.amazon.com/batch/)

---

## Scripts

```
docker build --tag batch-job-template .

docker run --rm batch-job-template HAL

docker tag batch-job-template:latest batch-job-template:v1.0.0

# Publish
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 924586450630.dkr.ecr.us-east-1.amazonaws.com

docker build --tag batch-job-template .

docker tag batch-job-template:latest 924586450630.dkr.ecr.us-east-1.amazonaws.com/batch-job-template:latest

docker push 924586450630.dkr.ecr.us-east-1.amazonaws.com/batch-job-template:latest

# Submit a job

aws batch submit-job \
--job-name getting-started-job-$(date '+%Y-%m-%d--%H-%M-%S') \
--job-queue getting-started-job-queue \
--job-definition getting-started-job-definition \
--parameters person=Haywood
```

