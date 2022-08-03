# Weplayed Stork

Delivering babies every day.



## Available functions

### wp_message

Render message into console, heavily used inside other functions. Accepts only positional
arguments.

Arguments are:

  * [0]: `INFO`, `WARNING` or `ERROR` - message level.

  * [@]: message body

### wp_execute

Used internally to run given command. If `DEBUG` env is set to anything except empty string, given
command will be echoed to STDOUT.

### wp_is_tag_build

Returns build tag if it matches to predefined tag format. Matching tag names examples:

  * v1

  * v0-anything-you-want

  * v1.12

  * v0.12-anything-you-want

  * v0.12.23-anything-you-want

Arguments:

  * `-t|--tag`: Pass tag name, defaults to `TRAVIS_TAG` environment variable value.

### wp_is_staging_build

Returns branch name if the build considered as staging.

Arguments:

  * `-t|--tag`: Pass tag name, defaults to `TRAVIS_TAG` environment variable value.

  * `-b|--branch`: Specify branch value, defaults to `TRAVIS_BRANCH` environment variable value.

### wp_is_demo_build

Returns current branch name if it matches git flow branch names like `feature/*`, `hotfix/*` or
`bugfix/*`

Arguments:

  * `-t|--tag`: Pass tag name, defaults to `TRAVIS_TAG` environment variable value.

  * `-b|--branch`: Specify branch value, defaults to `TRAVIS_BRANCH` environment variable value.

### wp_set_weplayed_env

Sets `WEPLAYED_ENV` environment variable according to provided arguments and/or environment
variables. It uses `wp_is_tag_build`, `wp_is_staging_build` and `wp_is_demo_build` internally
so all limitations explained in that functions also apply.

Arguments:

  * `-t|--tag`: Tag name. Defaults to `TRAVIS_TAG` env value.

  * `-b|--branch`: branch value, defaults to `TRAVIS_BRANCH` env value.

  * `-l|--live`: Specify env value for tag build.

  * `-s|--staging`: Environment variable value for staging build.

  * `-d|--demo`: .

### wp_s3_deploy

This function could be used for uploading files to AWS s3 under misc conditions.

All destinations specified by `-l`, `-s` and `-d` options should have standard `aws s3`
format like `s3://my-basket/path/to`.

Positional args is a list of source and destination pairs joined with comma. Local path is
relative to current directory, remote path is relative to destination selected by deploy type.

If single value specified instead of pair, both source and destination paths will have the
same value. If you need to upload some local folder into remote destination with no folder
suffixed, use `local_folder,` syntax. If current working dir is a source and needs to be
uploaded into some other remote folder, use `,remote/folder` syntax.

*NOTE:* upload won't happen if the `TRAVIS_EVENT_TYPE` env is equals to `pull_request`.

See `wp_is_tag_build`, `wp_is_staging_build` and `wp_is_demo_build` for explanation when
build considered as live, staging or demo.

Arguments:

  * `-p|--public`: Set `public-read` ACL during upload

  * `-t|--tag`: Specify tag and force tag build, in this case `-l|--live` should be present.
    defaults to `TRAVIS_TAG` environment variable value.

  * `-b|--branch`: Specify branch value, defaults to `TRAVIS_BRANCH` environment variable value.

  * `-l|--live`: Specify AWS s3 destination for tag build.

  * `-s|--staging`: Specify AWS s3 destination for staging build.

  * `-d|--demo`: Specify AWS s3 destination for git flow builds, really useful with branch
    placeholder.

Destination path placeholders:

  * `:branch:` - replaced with actual branch name value.

  * `:tag:` - replaced with actual tag value so makes sense only in tag build mode (`-l` option)

  * `:tagmajor:` - replaced with major part of tag name, e.g. if `--tag` is set to `v1.12.1`
    placeholder will be replaced to `v1` value.

#### Example:

Upload files from `dist` and `docs` local folders into different remote buckets:

    aws -p \
      -l s3://live/:tagmajor: \
      -s s3://staging \
      -d s3://demo/:branch: \
      dist, docs

Under different combination of environment variables upload will happen to different locations:

  * `TRAVIS_TAG=v1.12.1`
    * dist -> s3://live/v1
    * docs -> s3://live/v1/docs

  * `TRAVIS_BRANCH=develop`
    * dist -> s3://staging
    * docs -> s3://staging/docs

  * `TRAVIS_BRANCH=feature/stork`
    * dist -> s3://demo/feature/stork
    * docs -> s3://demo/feature/stork/docs
