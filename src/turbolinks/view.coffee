#= require ./snapshot
#= require ./element_pool

class Turbolinks.View
  constructor: (@delegate) ->
    @element = document.documentElement

  getSnapshot: ({clone} = {clone: true}) ->
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
      @element.dataset.turbolinksPreview = ""
    else
      delete @element.dataset.turbolinksPreview

  renderSnapshot: (newSnapshot, callback) ->
    currentSnapshot = @getSnapshot(clone: false)

    unless currentSnapshot.hasSameTrackedHeadElementsAsSnapshot(newSnapshot)
      @delegate.viewInvalidated()
      return false

    for element in newSnapshot.getInlineHeadElementsNotPresentInSnapshot(currentSnapshot)
      document.head.appendChild(element.cloneNode(true))

    for element in currentSnapshot.getTemporaryHeadElements()
      document.head.removeChild(element)

    for element in newSnapshot.getTemporaryHeadElements()
      document.head.appendChild(element.cloneNode(true))

    newBody = newSnapshot.body.cloneNode(true)
    @delegate.viewWillRender(newBody)

    importPermanentElementsIntoBody(newBody)
    importRecyclableElementsIntoBody(newBody)
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

  importRecyclableElementsIntoBody = (newBody) ->
    elementPool = new Turbolinks.ElementPool getRecyclableElements(document.body)
    for oldChild in getRecyclableElements(newBody)
      if newChild = elementPool.retrieveMatchingElement(oldChild)
        oldChild.parentNode.replaceChild(newChild, oldChild)

  getPermanentElements = (element) ->
    element.querySelectorAll("[id][data-turbolinks-permanent]")

  getRecyclableElements = (element) ->
    element.querySelectorAll("[data-turbolinks-recyclable]")

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
