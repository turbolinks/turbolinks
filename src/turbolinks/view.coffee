class Turbolinks.View
  constructor: (@delegate) ->

  loadHTML: (html) ->
    @loadSnapshotWithScrollPosition(parseHTML(html), "anchored")

  loadSnapshotWithScrollPosition: (snapshot, scrollPosition) ->
    document.title = snapshot.title
    document.body = snapshot.body

    if scrollPosition is "restored" and snapshot.offsets?
      xOffset = snapshot.offsets.left ? 0
      yOffset = snapshot.offsets.top ? 0
      scrollTo(xOffset, yOffset)
    else if element = (try document.querySelector(window.location.hash))
      element.scrollIntoView()
    else
      scrollTo(0, 0)

  saveSnapshot: ->
    body: document.body.cloneNode(true)
    title: document.title
    offsets:
      left: window.pageXOffset
      top: window.pageYOffset

  # Private

  parseHTML = (html) ->
    element = document.createElement("html")
    element.innerHTML = html
    title: element.querySelector("title")?.textContent
    body: element.querySelector("body")
