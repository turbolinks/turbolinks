#= require ./snapshot
#= require ./snapshot_renderer

class Turbolinks.View
  constructor: (@delegate) ->
    @element = document.documentElement

  getRootLocation: ->
    @getSnapshot().getRootLocation()

  getCacheControlValue: ->
    @getSnapshot().getCacheControlValue()

  getSnapshot: ({clone} = {clone: false}) ->
    element = if clone then @element.cloneNode(true) else @element
    Turbolinks.Snapshot.fromElement(element)

  render: ({snapshot, html, isPreview}, callback) ->
    @markAsPreview(isPreview)
    if snapshot?
      @renderSnapshot(Turbolinks.Snapshot.wrap(snapshot), callback)
    else
      @renderHTML(html, callback)

  # Private

  markAsPreview: (isPreview) ->
    if isPreview
      @element.setAttribute("data-turbolinks-preview", "")
    else
      @element.removeAttribute("data-turbolinks-preview")

  renderSnapshot: (newSnapshot, callback) ->
    renderer = new Turbolinks.SnapshotRenderer @getSnapshot(), newSnapshot
    renderer.delegate = @delegate
    renderer.render(callback)

  renderHTML: (html, callback) ->
    document.documentElement.innerHTML = html
    activateScripts()
    callback?()
    @delegate.viewRendered()

  activateScripts = ->
    for oldChild in document.querySelectorAll("script")
      newChild = cloneScript(oldChild)
      oldChild.parentNode.replaceChild(newChild, oldChild)

  cloneScript = (script) ->
    element = document.createElement("script")
    if script.hasAttribute("src")
      element.src = script.getAttribute("src")
    else
      element.textContent = script.textContent
    element
