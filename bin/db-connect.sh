# find the instance ID based on Tag Name
INSTANCE_ID=$(aws ec2 describe-instances \
               --filter "Name=tag:Name,Values=$AWS_SSM_TAG" \
               --query "Reservations[].Instances[?State.Name == 'running'].InstanceId[]" \
               --output text)

ssh -L 5432:$AWS_RDS_HOST:5432 $INSTANCE_ID.us-east-1.default -N
