This repository contains everything you need to deploy the LifeIn19x19 forums to
a local Docker installation. From there, it is easy to develop new features or
changes without affecting the site until they're ready to ship.

## Requirements

This deployment requires a recent version of [Docker](https://docker.com) and
[Docker Compose](https://docs.docker.com/compose/). It also helps to be an admin
on L19 since this allows you to work with an existing database, to test
compatibility with all our existing posts, uploads, and data.

## Instructions

1. Clone this repository together with its submodules:
```
$ git clone --recurse-submodules git@github.com:LifeIn19x19/deploy
$ cd deploy
```
  
2. _(Admin required)_: Generate a [database dump](https://lifein19x19.com/adm/index.php?i=database&mode=backup)
of the entire database (make sure to select all tables) and store it in the
`db/data` directory.

3. _(Admin required)_: Copy over any static resources (like uploaded SGFs or
avatars) from the production server to the `data` directory:
```
$ mkdir data/
$ rsync -avP l19:/var/www/forum/images data/
$ rsync -avP l19:/var/www/forum/files data/
```

4. Create a `production.env` file from the provided template and fill in
appropriate values:
```
$ cp production.env.template production.env
```

5. Create a `.env` file from the provided template and fill in appropriate
values. The default values (in the cases that they exist) are almost certainly
correct already unless you're deploying to prod:
```
$ cp .env.template .env
```

6. Bring up the site:
```
$ docker-compose up
```
The very first run will take quite a bit of time, since the database dump has
to be imported into the local MySQL instance. Subsequent runs will be nearly
instantaneous.

7. You can now access the dev site in your browser at http://localhost:8080/
