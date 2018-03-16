# Introduction

This guide explains how to install a fresh Decidim instance on top of Rancher using Docker. At the end of the process you will have a clean install of Decidim.

# Requirements

This guide assumes that you've installed [Docker](https://www.docker.com/) as well as [Docker Compose](https://docs.docker.com/compose/).

In order to upload the generated images you need a valid Docker Hub account.

# Installation Steps

## Create a Decidim application
The first thing that you need is a Decidim application. You can create a new one following the steps available at [Decidim starting guide](https://github.com/decidim/decidim/blob/master/docs/getting_started.md). For this guide we've forked
[Metadecidim](https://github.com/decidim/metadecidim) instead. [Metadecidim](https://github.com/decidim/metadecidim)
comes with Docker files for the web and worker container.

If you finally decide to go on your own and create a fresh decidim application you should check this files as well because you will need them during the upcoming sections.

## Build de Docker images.

At this step you need to build two Docker images. One for the web service and another for the worker.

In order to build the image for the web service in a terminal execute the follwing commands:

First login into docker.
```bash
$ docker login
```
Then create an image for web service. Notice that the generated image will be uploaded to Docker Hub account.
```bash
$ docker build -t jsperezg/decidim -f Dockerfile.web .
$ docker push jsperezg/decidim
```

Finally repeat the previous steps to create an image for the worker service:
```bash
$ docker build -t jsperezg/decidim-worker -f Dockerfile.worker .
$ docker push jsperezg/decidim-worker
```

At this point you should have two images for Decidim.

## Prepare the docker-compose.yml file.

Rancher requires a docker-compose.yml file in order to create a new Stack. Take your time to check the docker-compose.yml file that comes with this project:

```yml
version: '2'
services:
  decidim:
    image: jsperezg/decidim
    environment:
      - PORT=3000
      - DATABASE_HOST=pg
      - DATABASE_USERNAME=postgres
      - RAILS_ENV=production
      - REDIS_URL=redis://redis:6379
      - RAILS_SERVE_STATIC_FILES=1
      # - RAILS_FORCE_SSL=1
    ports:
      - 3000:3000
    links:
      - pg
      - redis
    entrypoint: ["/code/bin/entrypoint.sh"]
    command: bundle exec rails s -b 0.0.0.0
  worker:
    image: jsperezg/decidim-worker
    environment:
      - DATABASE_HOST=pg
      - DATABASE_USERNAME=postgres
      - RAILS_ENV=production
      - REDIS_URL=redis://redis:6379
    links:
      - pg
      - redis
    command: bundle exec sidekiq -C config/sidekiq.yml
  pg:
    image: postgres
    volumes:
      - pg-data:/var/lib/postgresql/data
  redis:
    image: redis
    volumes:
      - redis-data:/data
volumes:
  pg-data: {}
  redis-data: {}
```

Notice that the docker images for worker and decidim services point to the images that we've created during the previous steps.

## Verify that everything works.

At this point you should be able to start your Decidim application using docker compose:

```bash
$ docker-compose build --pull
$ docker-compose run decidim rails db:create
$ docker-compose run decidim rails db:migrate
$ docker-compose up
```

Once the containers have been initialized you should be able to browse to http://localhost:3000.

## Installation in Rancher.

Installation in Rancher is pretty straight forward: Just browse to your Rancher installation and follow these steps:

1. Go to menu Stacks/all
2. Press button 'Add stack'
3. Type a name and a description for your stack.
4. Select the docker compose file that you have previously created.
5. Press 'Create'

That's all. You should be able to browse to http://rancher_server:3000

## Additional steps

The first time the app is installed an administrator user needs to be created. To do so open a terminal into the Decidim
service and type the following commands in a rails console:

```bash
$ rails c
```

```rubyonrails
email = <your email>
password = <a secure password>
user = Decidim::System::Admin.new(email: email, password: password, password_confirmation: password)
user.save!
```
