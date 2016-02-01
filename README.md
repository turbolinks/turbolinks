# Turbolinks 5 Preview

**Turbolinks makes navigating your web application faster.** Get the performance benefits of a single-page application without the added complexity of a client-side JavaScript framework. Use HTML to render your views on the server side, and link to pages as usual. Turbolinks automatically fetches the page, swaps in its `<body>`, and merges its `<head>`, all without incurring the cost of a full page load.

Developed for the all-new [Basecamp 3](https://basecamp.com/3/), Turbolinks 5 is a complete rewrite that adds support for iOS and Android hybrid applications. This preview release is API-stable, but [official documentation](https://github.com/turbolinks/turbolinks/tree/docs#readme) remains a work in progress.

#### Quick Installation for Rails Applications

1. Add the `turbolinks` gem, version 5, to your Gemfile:
```ruby
gem 'turbolinks', '~> 5'
```
2. Run `bundle install`.
3. Add `//= require turbolinks` to your JavaScript manifest file (usually found at `app/assets/javascripts/application.js`).

#### Using Turbolinks Outside of a Rails Application

Simply include [`dist/turbolinks.js`](dist/turbolinks.js) in your app's JavaScript bundle.

# Frequently Asked Questions

#### Why did you rewrite Turbolinks?

At Basecamp, we’re big believers in the [hybrid approach to building native applications](https://blogcabin.37signals.com/posts/3743-hybrid-sweet-spot-native-navigation-web-content): server-generated web views wrapped in, and enhanced by, native navigation controls. And Turbolinks’ page replacement strategy is the key ingredient to making our web views fast.

We were able to integrate Turbolinks into our hybrid apps for Basecamp 3, but not with the level of fidelity we expected from a native application. Eventually, we determined we’d need to redesign Turbolinks with more than just the browser in mind.

Rewriting Turbolinks from the ground up let us isolate the browser-specific behavior behind a pluggable adapter interface,  with hooks in place for explicit control over every step of navigation. The rewrite also gave us a fresh slate to simplify the API, revisit past philosophical decisions, and trim some technical baggage.

#### Why is it called Turbolinks 5? What happened to versions 3 and 4?

Version 2.5.3 is the most recent official release of Turbolinks; version 3 has been in development for some time without an official release. We are preserving the original code base as Turbolinks Classic, and all existing issues and pull requests remain at [turbolinks/turbolinks-classic on GitHub](https://github.com/turbolinks/turbolinks-classic).

We wanted to signify that this rewrite is a major leap with a backwards-incompatible API. While we could have gone with version 4, we thought 5 had a nice ring to it, given that it coincides with the upcoming Rails 5 release.

#### Why did you remove partial replacement?

[Partial replacement](https://github.com/rails/turbolinks#partial-replacement-30) is an API introduced in the unreleased Turbolinks 3 which allows you to pick and choose individual elements for replacement during navigation.

It’s our opinion that partial replacement is mostly orthogonal to the responsibilities of navigating between pages. Partial replacement drastically expands the scope of Turbolinks’ API, and we feel the tradeoff between performance and complexity it introduces is not in line with the Turbolinks philosophy.

However, we’ve kept Turbolinks 3’s concept of “permanent” elements via the `data-turbolinks-permanent` annotation. Placing this annotation on any element with an ID allows that element to persist across page changes. We think this feature gives you 90% of the benefits of partial replacement with 10% of its complexity.

#### Should I use Turbolinks 5 or Turbolinks Classic?

Consider using Turbolinks 5 now if you are starting work on a new application and don’t mind consulting the source code when something doesn’t work.

If you have an existing application built with Turbolinks Classic, you may wish to wait until the final release of Turbolinks 5 before upgrading.

Note that the API has changed. In particular, all of the Turbolinks Classic events have been renamed, and several—including `page:update`—have been removed. We’ve made available a [basic compatibility shim](src/turbolinks/compatibility.coffee) for Turbolinks Classic events for use during the transition.

#### Where can I find the iOS and Android adapters?

Our iOS and Android adapters let you build hybrid apps which combine native navigation patterns with a single shared web view.

We plan on open-sourcing these adapters in the next few weeks. To see the adapters in action, check out our [Basecamp 3 for iOS](https://itunes.apple.com/us/app/id1015603248) and [Basecamp 3 for Android](https://play.google.com/store/apps/details?id=com.basecamp.bc3) apps.

#### Will my third-party libraries work with Turbolinks 5?

As with previous versions of Turbolinks, you may encounter problems with third-party libraries which do the following:

* Add event listeners directly to page elements (including `<body>`)
* Install behavior on `DOMContentLoaded` or `window.onload`

To work around these issues, prefer using event delegation on `document.documentElement`, `document`, or `window`, and consider using `MutationObserver` to install behavior on elements as they’re added to the page.

Additionally, libraries which feature Turbolinks Classic integration may not work as expected with Turbolinks 5.
