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
--job-name ik-dev-batch-example-$(date '+%Y-%m-%d--%H-%M-%S') \
--job-queue ik-dev-batch-example \
--job-definition ik-dev-batch-example \
--parameters person=Haywood

# Update job definition image
# (normally done via CodePipeline)
OLD_JOB_DEFINITION=$(aws batch describe-job-definitions \
    --job-definition-name ik-dev-batch-example \
    | jq -c '.jobDefinitions[0]')
NEW_JOB_DEFINITION=$(echo $OLD_JOB_DEFINITION \
    | jq -c --arg image "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-batch-example-main:main-4" '.containerProperties.image = $image' \
    | jq -c 'del(.jobDefinitionArn)' \
    | jq -c 'del(.revision)' \
    | jq -c 'del(.status)')
aws batch register-job-definition \
    --type container \
    --job-definition ik-dev-batch-example \
    --cli-input-json "$NEW_JOB_DEFINITION"

# Describe AWS resources
mkdir build
aws batch describe-compute-environments > ./build/compute_environments.json
aws batch describe-job-queues > ./build/job_queues.json
aws batch describe-job-definitions > ./build/job_definitions.json
```

---

## Terraform

This project uses Terraform to manage AWS resources. It depends on [template-infrastructure](https://github.com/ikenley/template-infrastructure) for foundational infrastructure (e.g. VPC subnets).

```
cd terraform/dev
terraform init
terraform apply
```
