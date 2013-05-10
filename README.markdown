# HubCap

HubCap provides a web presentation layer on top of GitHub issues, pull-requests
and milestones organised by tags and assignment.

There are three main views:

1. Work board - shows all issues in current workflow
2. User board - groups current work by user
3. Release board - shows work grouped by milestone

![](http://cdn.ennova.com.au/hubcap/hubcap-screenshot-2013-05-09.png)

## Using labels and milestones to control layout and markers

The following labels are used to define the workflow steps:

* `0 - backlog`
* `1 - ready`
* `2 - working`
* `3 - review`
* `4 - done`

The following labels are used to define 'markers':

* `blocked`
* `accepted`
* `bug`
* `important`

We use 2 main milestones, `next` and `next+1` for the Release Board.

_See the [Roadmap](#roadmap) for future customisability._

## Development

```
git clone https://github.com/ennova/hubcap.git
cd hubcap
bundle install
brew install redis # if you're not on OS X, turn to Google
```

Create a `.env` file in the root of your project with the following
environment variable set:

``` sh
# .env
# your GitHub username
GITHUB_USERNAME=
# your GitHub password
GITHUB_PASSWORD=
# username or organisation username
GITHUB_USER=
# repo with the issues
GITHUB_REPO=
# comma separated list of name translations
NAME_MAPPING='AdrianSmith=Adrian,twe4ked=Odin'
# shared password for basic HTTP authentication (username is 'admin')
PASSWORD=
```

To run the app, first start Redis then run `rackup`.

```
redis-server
rackup
```

## Deploying to Heroku

```
heroku create
git push heroku master
heroku addons:add rediscloud:20
# set environment variables `heroku help config`
```

## Roadmap

* OAuth
* Ability to customise tags
* Admin area to select project and users

## License

MIT.

## Sponsored by

All this was made possible by [Ennova].

[Ennova]: http://ennova.com.au
