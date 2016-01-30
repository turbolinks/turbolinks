# Turbolinks

**Turbolinks makes navigating your web site faster.** In standard browser navigation every page is loaded anew. Resources are downloaded, JavaScript is evaluated, and CSS is processed. This takes time. But in most web applications these resources don't change between requests. So why spend time reloading them? Turbolinks speeds up navigation by persisting the current page and updating its contents in place, without reloading expensive resources. The result is dramatically improved load times.

## Features

- Optimizes navigation automatically. No need to annotate links or specify which parts of the page should change.
- No server-side cooperation neccessary. Respond with full HTML pages, not fragments.
- Instant navigation with caching. Recently-visited pages are redisplayed immediately and updated when a fresh response arrives.
- Custom adapters allow for precise, fine-grained control of the navigation lifecycle.

## Supported Browsers

Turbolinks supports all modern desktop and mobile browsers. It relies on the [HTML 5 History API](http://caniuse.com/#search=pushstate) and is disabled in its absence; navigation falls through to the browser.

# Installation

Turbolinks is currently packaged for use via the Rails Asset Pipeline. Typical installation is via Bundler:

1. Add `gem 'turbolinks', github: 'basecamp/turbolinks', branch: 'v5'` to your Gemfile.
2. Run `bundle install`.
3. Require `turbolinks` in your application's JavaScript manifest.
4. Restart your server.

Note: this is expected to change. We intend to release the core of Turbolinks as a pure JavaScript library with no dependencies. Rails integration will be shipped as a separate library, `turbolinks-rails`.

# How it works

Turbolinks works by listening for clicks on `<a>` elements referencing a location on the current origin. When an eligible link is clicked, Turbolinks requests its location via XHR, loads the response, and updates the `head` and `body` of the current page without replacing the `document`. Critically, external `script`, `style`, and `link` elements are considiered *permanent* and are not replaced.

Turbolinks is designed to emulate standard browser behavior as closely as possible: location, history, page title, and scroll position behave exactly as you'd expect.

## Navigating with Turbolinks

Internally, Turbolinks models navigation as a *visit* to a *location* with an *action*. Actions are named for the effect they have on history.

New navigation (e.g. clicking a link) has an action of either *advance* or *replace* and creates or updates a history entry respectively. In both cases Turbolinks will request the given location over the network. If available, a cached version will be shown immediately and updated when the response arrives.

History navigation (e.g. clicking the "back" button) has an action of *restore* and returns to a previous history entry. If available, a cached version of the restored location will be shown immediately and *no* network request will be made to refresh it. Otherwise a request will be performed. In either case, scroll position will be restored.

### Specifying an Action

The default action when clicking a link is *advance*. To specify that *replace* be used instead, annotate link elements with `data-turbolinks-action=replace`.

```html
<a href="/" data-turbolinks-action=replace>Home</a>
```

Restores are reserved for internal use during history navigation.

## Navigating Programmatically

To navigate programatically call `Turbolinks.visit` with a *location* and an optional *action*. The action can be either "advance" or "replace". The default action is "advance".

```javascript
// Visit this location and push a new history entry
Turbolinks.visit("/news")
Turbolinks.visit("/news", { action: "advance" })

// Replace the current history entry
Turbolinks.visit("/news", { action: "replace" })
```

Note that programmatic visits trigger the `turbolinks:visit` event and may be canceled by listeners, in which case no navigation will occur.

## Observing Navigation Events

Turbolinks emits events that allow you to track the navigation lifecycle and respond to page loading. Except where noted, events are fired on `document`.

- `turbolinks:click` fires when a Turbolinks-enabled link is clicked. The clicked element is the event target. Access the requested location with `event.data.url`. Cancelable.
- `turbolinks:visit` fires before visiting a location. Does not fire when navigating by history. Access the requested location with `event.data.url`. Cancelable.
- `turbolinks:request-start` fires before issuing a network request to fetch a page.
- `turbolinks:request-end` fires after a network request completes.
- `turbolinks:before-cache` fires before the current page is saved to the cache.
- `turbolinks:render` fires after rendering the page. Fires twice when advancing to a cached location: once after rendering the cached version and again after rendering the fresh version.
- `turbolinks:load` fires after the page is fully loaded.

## Page Caching

Turbolinks caches the 10 most-recently-visited pages in memory for instant display on the next visit. The current page is saved to the cache just prior to it being replaced, ensuring that changes made to the DOM after the initial load will be reflected.

Observe the `turbolinks:before-cache` event if you need to make changes or clean up any state before the page is saved.

You can clear the page cache at any time by calling `Turbolinks.clearCache()`.

## Displaying Progress

Because Turbolinks navigation proceeds without a full load, the browser's native progress indicator won't be activated. Turbolinks ships with a JavaScript and CSS-based progress bar to compensate.

The progress bar is implemented as a `<div>` element with the class name `.turbolinks-progress-bar`. Its default styles are included first in the document head such that they can be overridden by rules that come later. For example, a thick green progress bar:

```css
.turbolinks-progress-bar {
  height: 5px;
  background-color: green;
}
```

## Reloading When Assets Change

Turbolinks can track asset URLs and reload automatically when they change. Ensure you can invalidate assets by URL (a common practise is to include a digest of the asset in its name) and denote tracked assets with `data-turbolinks-track=reload`.

```html
<head>
  ...
  <link rel="stylesheet" href="/application-258e88d.css" data-turbolinks-track=reload>
  <script src="/application-cbd3cd4.js" data-turbolinks-track=reload></script>
</head>
```

## Opting Out

Turbolinks is automatically enabled for internal links to HTML documents on the same origin. You can opt out of Turbolinks explicitly by annotating a link or any of its ancestors with `data-turbolinks=false`. To reenable when an ancestor has opted out, use `data-turbolinks=true`.

```html
<a href="/">Enabled</a>
<a href="/" data-turbolinks=false>Disabled</a>

<div data-turbolinks=false>
  <a href="/">Disabled</a>
  <a href="/" data-turbolinks=true>Enabled</a>
</div>
```
---

# Advanced Usage

## Permanent Elements

## Recyclable Elements

## Setting a Root Location

# Differences From Earlier Versions

# Known Issues

- Missing a polyfill for `Promise`.
- Anchored links to the current location deviate from standard browser behavior by making a network request.
- Snapshot#hasAnchor() doesn't consider named anchors like `<a name="top"></a>`.
- Visiting with an unrecognized action triggers an error when history is changed. We should fail sooner when an invalid action is specified.

---

# Contributing to Turbolinks

Turbolinks is open-source software, freely distributable under the terms of an [MIT-style license](MIT-LICENSE). The source code is hosted on GitHub.
