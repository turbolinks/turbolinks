#= require turbolinks/snapshot
#= require turbolinks/element_pool

class Turbolinks.View
  constructor: (@delegate) ->

  loadHTML: (html) ->
    snapshot = Turbolinks.Snapshot.fromHTML(html)
    @loadSnapshotByScrollingToSavedPosition(snapshot, "anchor")

  loadSnapshotByScrollingToSavedPosition: (snapshot, scrollToSavedPosition) ->
    @loadSnapshot(snapshot)
    @scrollSnapshotToSavedPosition(snapshot, scrollToSavedPosition)

  saveSnapshot: ->
    getSnapshot(true)

  # Private

  loadSnapshot: (newSnapshot) ->
    currentSnapshot = getSnapshot(false)

    unless currentSnapshot.hasSameTrackedHeadElementsAsSnapshot(newSnapshot)
      return window.location.reload()

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

  scrollSnapshotToSavedPosition: (snapshot, scrollToSavedPosition) ->
    location = window.location.toString()

    if scrollToSavedPosition and snapshotOffsets?
      xOffset = snapshot.scrollLeft
      yOffset = snapshot.scrollTop
      scrollTo(xOffset, yOffset)
    else if element = (try document.querySelector(window.location.hash))
      element.scrollIntoView()
    else if @lastScrolledLocation isnt location
      scrollTo(0, 0)

    @lastScrolledLocation = location

  getSnapshot = (clone) ->
    new Turbolinks.Snapshot
      head: maybeCloneElement(document.head, clone)
      body: maybeCloneElement(document.body, clone)
      scrollLeft: window.pageXOffset
      scrollTop: window.pageYOffset

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

  maybeCloneElement = (element, clone) ->
    if clone then element.cloneNode(true) else element
