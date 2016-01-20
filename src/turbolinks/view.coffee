#= require ./snapshot
#= require ./element_pool

class Turbolinks.View
  constructor: (@delegate) ->

  loadDocumentHTML: (html) ->
    document.documentElement.innerHTML = html
    activateScripts()

  loadSnapshotHTML: (html) ->
    snapshot = Turbolinks.Snapshot.fromHTML(html)
    @loadSnapshot(snapshot)

  loadSnapshot: (snapshot) ->
    @renderSnapshot(snapshot)

  saveSnapshot: ->
    Turbolinks.Snapshot.fromElement(document.documentElement.cloneNode(true))

  # Private

  renderSnapshot: (newSnapshot) ->
    currentSnapshot = Turbolinks.Snapshot.fromElement(document.documentElement)

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
    importPermanentElementsIntoBody(newBody)
    importRecyclableElementsIntoBody(newBody)
    document.body = newBody

    focusFirstAutofocusableElement()
    @delegate.viewRendered()
    newSnapshot

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
