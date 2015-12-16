# Shrine example

This is an example app demonstrating how easy it is to complex file uploads
using [Shrine]. It implements the perfect user experience™ (like Google's),
and the underlying complexity is completely hidden away from the user.

The application allows the user to do multiple file uploads via AJAX, directly
to S3, where additional processing and deleting is done in background jobs.

## Requirements

To run the app you need to setup the following things:

* Install ImageMagick:

  ```rb
  $ brew install imagemagick
  ```

* Install the gems:

  ```rb
  $ bundle install
  ```

* Have Postgres on your machine, and run

  ```sh
  $ sequel -m db/migrations sqlite://database.sqlite3
  ```

* Put your Amazon S3 credentials in `.env` and [setup CORS].

  ```sh
  S3_ACCESS_KEY_ID="..."
  S3_SECRET_ACCESS_KEY="..."
  S3_REGION="..."
  S3_BUCKET="..."
  ```

Once you have all of these things set up, you can run the app:

```sh
$ bundle exec rackup
```

[Shrine]: https://github.com/janko-m/shrine
[setup CORS]: http://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
