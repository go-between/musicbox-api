aws2 ecs run-task --cluster musicbox-cluster-staging --task-definition musicbox-app-task-staging-db-migrate --count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[REPLACE_ME,WITH_PRIVATE_SUBNETS],securityGroups=[REPLACE_ME_WITH_ECS_SECURITY_GROUP]}"
