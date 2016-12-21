#= require ./snapshot
#= require ./snapshot_renderer
#= require ./error_renderer

class Turbolinks.View
  constructor: (@delegate) ->
    @element = document.documentElement

  getRootLocation: ->
    @getSnapshot().getRootLocation()

  getElementForAnchor: (anchor) ->
    @getSnapshot().getElementForAnchor(anchor)

  getSnapshot: ->
    Turbolinks.Snapshot.fromElement(@element)

  render: ({snapshot, error, isPreview}, callback) ->
    @markAsPreview(isPreview)
    if snapshot?
      @renderSnapshot(snapshot, isPreview, callback)
    else
      @renderError(error, callback)

  # Private

  markAsPreview: (isPreview) ->
    if isPreview
      @element.setAttribute("data-turbolinks-preview", "")
    else
      @element.removeAttribute("data-turbolinks-preview")

  renderSnapshot: (snapshot, isPreview, callback) ->
    Turbolinks.SnapshotRenderer.render(@delegate, callback, @getSnapshot(), Turbolinks.Snapshot.wrap(snapshot), isPreview)

  renderError: (error, callback) ->
    Turbolinks.ErrorRenderer.render(@delegate, callback, error)
