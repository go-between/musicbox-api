# Musicbox (API)

## First Things First

- [Homebrew](https://brew.sh/)
  - `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
- [rbenv](https://github.com/rbenv/rbenv#homebrew-on-macos)
  - `brew install rbenv`
  - `rbenv init`
- [Docker](https://www.docker.com/get-started)
  - Go to the link and find the download thing.  Do the rest of the instructions.

## Second Things Next

We use Docker to run the api and its constituent services, but we still need ruby locally to run the setup script and it's helpful to be able to run tests outside of Docker.

1.  Make sure that docker is running
2.  Ensure that the appropriate ruby version is installed
    > rbenv install
3.  You may need to update your version of bundler
    > gem update bundler
4.  You may need to install postgresql
    > brew install postgresql
5.  Install gems
    > bin/bundle install
6.  Copy the env template (Replace any ENV vars that need replacing.)
    > cp .env.template .env
7.  Setup the services
    > bin/setup
8.  Bring everything up (in the background)
    > docker-compose up -d

Note that setting up the services with `bin/setup` will create the appropriate databases, run migrations, and execute a small seed data task.  Now the API should be available!

## Important Routes

- [http://localhost:3000/graphiql](http://localhost:3000/graphiql)
  - The GraphQL graphical query interface.  Allows you to perform arbitrary queries and see results.
  - **NOTE:** Many queries/mutations execute within the context of the current authenticated user.  The [graphiql initialize](config/initializers/graphiql.rb) assumes that the seed script has been run and will attempt to use the user identified by the email **a@a.a**.  If this user does not exist, you'll probably get a bunch of errors on the graphiql page.
- [http://localhost:3000/workers](http://localhost:3000/workers)
  - The Sidekiq dashboard where you can see your background workers while away the hours while waiting on work to do.

## Seeded Data

The seed task drops some helpful data in the database so that you can get started poking around without first jumping in a rails console to create a user, etc.  In general:

### Jorm Nightengale
Email:  **a@a.a**  
Password:  **hunter2**

### Flawn Sprangboot
Email:  **b@b.b**  
Password:  **hunter2**

Users belong to one or more teams, which have several rooms.  Users also have some sweet music already in their library.  Check out [`db/seeds.rb`](db/seeds.rb) for the specifics!

## Deployment

### Push Code Places

We deploy as containerized services to ECS via Fargate.  At least I think I have all of those AWS words correct.  In order for YOU to deploy, you must:

1.  Have access to our Elastic Container Repository.  This means you'll need a user in our AWS account with some permissions.  Check with Truman because it's still a manual process.
2.  Have Docker running locally
3.  Execute `bin/build-push.sh`.  This will build a docker image and push it to ECR with the **latest** tag.  We use the tag when new ECS tasks go fetch the code that they're going to run, so we'll need to figure out how to coordinate this tag with our [Terraform Project](https://github.com/go-between/musicbox-terraform).  For right now, tasks always pull the (literal) **latest** tag, so be careful!
4.  Go over to the [Terraform Project](https://github.com/go-between/musicbox-terraform) and, like, make sure it's all set up.  Maybe there will be a README when you go there!  Follow whatever instructions we have for executing the deployment.

### Migrations

We run migrations as one-off ECS tasks.  They also currently pull their application from the **latest** docker tag in ECR, which means we technically have to deploy code before we can run migrations, which is not so great.  Maybe we'll fix that!  We have two database tasks that are parameterized by environment variables.

#### Staging
- Database Creation: `bin/db-create.sh` (probably we don't have to do this one too often)
  - AWS_ECS_CLUSTER: `musicbox-cluster-staging`
  - AWS_TASK_DEFINITION: `musicbox-app-task-staging-db-create`
  - AWS_PRIVATE_SUBNETS: The IDs of the private subnets in the VPC that you're deploying into, e.g., `subnet-xxxxxxxxxxxxxxxxx,subnet-yyyyyyyyyyyyyyyyy`
  - AWS_SECURITY_GROUPS: The IDs of the ECR and ECS Tasks security groups, e.g., `sg-xxxxxxxxxxxxxxxxx,sg-yyyyyyyyyyyyyyyyy`
  - EX: `AWS_TASK_DEFINITION=musicbox-app-task-staging-db-create AWS_ECS_CLUSTER=musicbox-cluster-staging AWS_PRIVATE_SUBNETS=subnet-xxxxxxxxxxxxxxxxx,subnet-yyyyyyyyyyyyyyyyy AWS_SECURITY_GROUPS=sg-xxxxxxxxxxxxxxxxx,sg-yyyyyyyyyyyyyyyyy bin/db-create.sh`
  - Yowzo!

- Database Migrations: `bin/db-migrate.sh` (remember that this task uses the **latest** tag by default so we'll have to figure out how to get around that!)
  - AWS_ECS_CLUSTER: `musicbox-cluster-staging`
  - AWS_TASK_DEFINITION: `musicbox-app-task-staging-db-migrate`
  - AWS_PRIVATE_SUBNETS: The IDs of the private subnets in the VPC that you're deploying into, e.g., `subnet-xxxxxxxxxxxxxxxxx,subnet-yyyyyyyyyyyyyyyyy`
  - AWS_SECURITY_GROUPS: The IDs of the ECR and ECS Tasks security groups, e.g., `sg-xxxxxxxxxxxxxxxxx,sg-yyyyyyyyyyyyyyyyy`
  - EX: `AWS_TASK_DEFINITION=musicbox-app-task-staging-db-migrate AWS_ECS_CLUSTER=musicbox-cluster-staging AWS_PRIVATE_SUBNETS=subnet-xxxxxxxxxxxxxxxxx,subnet-yyyyyyyyyyyyyyyyy AWS_SECURITY_GROUPS=sg-xxxxxxxxxxxxxxxxx,sg-yyyyyyyyyyyyyyyyy bin/db-migrate.sh`
  - Yowzo!

## Operationaling

