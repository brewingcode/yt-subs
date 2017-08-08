# yt-subs

A sortable list-view of the most recent videos from your Youtube
subscriptions. I find Youtube's UI annoying to quickly look up recent
videos for the channels I care about the most.

https://yt.brewingcode.net

![example screen recording](https://thumbs.gfycat.com/FearlessDimwittedGrackle-size_restricted.gif)

This is an [Ember CLI app](BOILERPLATE.md) with the following main additions:

* [ember-cli-coffeescript](https://github.com/kimroen/ember-cli-coffeescript) for cleaner and simpler JS
* [ember-cli-emblem](https://github.com/Vestorly/ember-cli-emblem) for cleaner and simpler HTML
* [bootstrap-stylus](https://github.com/maxmx/bootstrap-stylus) for cleaner and simpler CSS
* [ember-inject-script](https://github.com/minutebase/ember-inject-script) for Ember-compatible Google oauth and API calls
* [ember-cli-deploy](https://github.com/ember-cli-deploy/ember-cli-deploy) (and a bazillion plugins) for deploying to S3
* [ember-local-storage](https://github.com/funkensturm/ember-local-storage) to persist your actions in local storage

The important files:

* The main application: [template](app/templates/application.emblem), [code](app/controllers/application.coffee)
* The list of channels and videos: [template](app/templates/components/yt-videos.emblem), [code](app/components/yt-videos.coffee)
* The Ember Service to interface with Google's APIs for oauth and youtube: [code](app/services/google-api.coffee)
* The two APIS used are [subscriptions](https://developers.google.com/youtube/v3/docs/subscriptions/list) and
  [search](https://developers.google.com/youtube/v3/docs/search/list)

[Ember CLI Boilerplate](BOILERPLATE.md)
