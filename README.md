# Weplayed Stork

Delivering babies every day.



## Available functions

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

Options:

  * `-p|--public`: Set `public-read` ACL during upload

  * `-t|--tag`: Specify tag and force tag build, in this case `-l|--live` should be present.
    defaults to `TRAVIS_TAG` environment variable value.

  * `-b|--branch`: Specify branch value, defaults to `TRAVIS_BRANCH` environment variable value.

  * `-l|--live`: Specify AWS s3 destination for tag build.
    *NOTE*: live (tag) deploy requires tag value to be in predefined format like `v1`, `v2.28` etc,
    otherwise deploy will be skipped.

  * `-s|--staging`: Specify AWS s3 destination for staging builds - branch equals to `develop`
    value

  * `-d|--demo`: Specify AWS s3 destination for git flow builds, i.e. branch has on of
    `feature/`, `hotfix/` or `bugfix/` prefixes, really useful with branch placeholder.

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
