class Turbolinks.History
  constructor: (@delegate) ->
    @state = { turbolinks: true }

  push: (location) ->
    unless @initialized
      @update("replace", null)
      @initialized = true

    @update("push", location)
    @delegate.historyChanged(location)

  replace: (location) ->
    @update("replace", location)
    @delegate.historyChanged(location)

  # Private

  update: (method, location) ->
    history[method + "State"](@state, null, location)
