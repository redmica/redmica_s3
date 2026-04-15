#!/bin/bash
set -e

cd /redmica

cat > config/database.yml << EOF
default: &default
  adapter: postgresql
  database: redmine
  username: postgres
  host: db
  port: 5432
  encoding: utf8
  collation: C
  ctype: C
  template: template0

development:
  <<: *default
production:
  <<: *default
test:
  <<: *default
  database: redmine-test
EOF

cat > config/s3.yml << EOF
default: &default
  access_key_id: test
  secret_access_key: test
  bucket: redmine-bucket
  folder: attachments
  thumb_folder: attachments/thumbnails/
  import_folder: attachments/imports/

development:
  <<: *default
production:
  <<: *default
test:
  <<: *default
EOF

bundle install

bin/rails generate_secret_token
bin/rails db:create db:migrate

bin/rails r "RedmicaS3::Connection.send(:own_bucket).tap { |bucket| bucket.create unless bucket.exists? }"

exec "$@"
