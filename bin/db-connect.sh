# find the instance ID based on Tag Name
INSTANCE_ID=$(aws ec2 describe-instances \
               --filter "Name=tag:Name,Values=$AWS_SSM_TAG" \
               --query "Reservations[].Instances[?State.Name == 'running'].InstanceId[]" \
               --output text)

# create the port forwarding tunnel
aws ssm start-session --target $INSTANCE_ID \
                       --document-name AWS-StartPortForwardingSession \
                       --parameters '{"portNumber":["22"],"localPortNumber":["55432"]}'
