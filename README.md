# S3 plugin for Redmine/RedMica

[![Test](https://github.com/redmica/redmica_s3/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/redmica/redmica_s3/actions/workflows/test.yml)

## Description
This [Redmine](http://www.redmine.org) plugin makes file attachments be stored on [Amazon S3](http://aws.amazon.com/s3) rather than on the local filesystem. This is a fork for [original gem](http://github.com/tigrish/redmine_s3) and difference is that this one supports [RedMica](https://github.com/redmica/redmica) 3.1.0 and later(compatible with Redmine 6.0.0 and later)

## Installation
1. Make sure Redmine is installed and cd into it's root directory
2. `git clone https://github.com/redmica/redmica_s3.git plugins/redmica_s3`
3. `cp plugins/redmica_s3/config/s3.yml.example config/s3.yml`
4. Edit config/s3.yml with your favourite editor
5. `bundle install --without development test` for installing this plugin dependencies (if you already did it, doing a `bundle install` again would do no harm)
6. Restart web server/upload to production/whatever
7. *Optional*: Run `rake redmica_s3:files_to_s3` to upload files in your files folder to s3

## Options Detail
* access_key_id: string key (required)
* secret_access_key: string key (required)
* bucket: string bucket name (required)
* folder: string folder name inside bucket (for example: 'attachments')
* endpoint: string endpoint instead of s3.amazonaws.com
* region: string aws region (activate when endpoint is not set)
* thumb_folder: string folder where attachment thumbnails are stored; defaults to 'tmp'
* import_folder: string folder where import files are stored temporarily; defaults to 'tmp'

## Forked From
* https://github.com/tigrish/redmine_s3
* https://github.com/ka8725/redmine_s3

## Development with Docker

### Prerequisites

* Docker

### Launching Redmine

```
cd docker/
docker compose up -d app
docker compose exec app bin/rails s
```

If you want to run Redmine in production mode, you can use the following command:

```
docker compose exec app bin/rails s -e production
```

Visit http://localhost:3000 to access Redmine.

### Running Tests

```
cd docker/
docker compose up -d --wait
docker compose exec app bin/rails redmine:plugins:test NAME=redmica_s3
```

> [!Note]
> You also need to have the selenium service running to exexute tests.

## License
This plugin is released under the [MIT License](http://www.opensource.org/licenses/MIT).
