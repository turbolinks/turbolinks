#= require ./snapshot

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

  shouldCacheSnapshot: ->
    @getCacheControlValue() isnt "no-cache"

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
    currentSnapshot = @getSnapshot()

    unless currentSnapshot.hasSameTrackedHeadElementsAsSnapshot(newSnapshot)
      @delegate.viewInvalidated()
      return false

    for element in newSnapshot.getInlineHeadElementsNotPresentInSnapshot(currentSnapshot)
      element = if @shouldCacheSnapshot() then element.cloneNode(true) else element
      document.head.appendChild(element)

    for element in currentSnapshot.getTemporaryHeadElements()
      document.head.removeChild(element)

    for element in newSnapshot.getTemporaryHeadElements()
      element = if @shouldCacheSnapshot() then element.cloneNode(true) else element
      document.head.appendChild(element)

    newBody = if @shouldCacheSnapshot()
      newSnapshot.body.cloneNode(true)
    else
      newSnapshot.body

    @delegate.viewWillRender(newBody)

    importPermanentElementsIntoBody(newBody)
    document.body = newBody

    focusFirstAutofocusableElement()
    callback?()
    @delegate.viewRendered()

  renderHTML: (html, callback) ->
    document.documentElement.innerHTML = html
    activateScripts()
    callback?()
    @delegate.viewRendered()

  importPermanentElementsIntoBody = (newBody) ->
    for newChild in getPermanentElements(document.body)
      if oldChild = newBody.querySelector("[id='#{newChild.id}']")
        oldChild.parentNode.replaceChild(newChild, oldChild)

  getPermanentElements = (element) ->
    element.querySelectorAll("[id][data-turbolinks-permanent]")

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

  focusFirstAutofocusableElement = ->
    document.body.querySelector("[autofocus]")?.focus()
