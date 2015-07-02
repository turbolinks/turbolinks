class Turbolinks.View
  constructor: (@delegate) ->

  loadHTML: (html) ->
    @loadSnapshot(parseHTML(html))

  loadSnapshot: (snapshot) ->
    document.title = snapshot.title
    document.body = snapshot.body
    window.pageXOffset = snapshot.offsets?.left ? 0
    window.pageYOffset = snapshot.offsets?.top ? 0

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
