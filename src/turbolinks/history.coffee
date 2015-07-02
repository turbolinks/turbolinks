class Turbolinks.History
  constructor: (@delegate) ->
    @state = { turbolinks: true }

  push: (url) ->
    unless @initialized
      @update("replace", null)
      @initialized = true

    @update("push", url)
    @delegate.historyChanged(url)

  replace: (url) ->
    @update("replace", url)
    @delegate.historyChanged(url)

  # Private

  update: (method, url) ->
    history[method + "State"](@state, null, url)
