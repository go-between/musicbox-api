6# Musicbox (API)

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

