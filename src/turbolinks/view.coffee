class Turbolinks.View
  constructor: (@delegate) ->

  loadHTML: (html) ->
    @loadSnapshotByScrollingToSavedPosition(parseHTML(html), "anchor")

  loadSnapshotByScrollingToSavedPosition: (snapshot, scrollToSavedPosition) ->
    document.title = snapshot.title
    document.body = snapshot.body
    @scrollToSavedPositionWithOffsets(scrollToSavedPosition, snapshot.offsets)

  saveSnapshot: ->
    body: document.body.cloneNode(true)
    title: document.title
    offsets:
      left: window.pageXOffset
      top: window.pageYOffset

  # Private

  scrollToSavedPositionWithOffsets: (scrollToSavedPosition, snapshotOffsets) ->
    location = window.location.toString()

    if scrollToSavedPosition and snapshotOffsets?
      xOffset = snapshotOffsets.left ? 0
      yOffset = snapshotOffsets.top ? 0
      scrollTo(xOffset, yOffset)
    else if element = (try document.querySelector(window.location.hash))
      element.scrollIntoView()
    else if @lastScrolledLocation isnt location
      scrollTo(0, 0)

    @lastScrolledLocation = location

  parseHTML = (html) ->
    element = document.createElement("html")
    element.innerHTML = html
    title: element.querySelector("title")?.textContent
    body: element.querySelector("body")
