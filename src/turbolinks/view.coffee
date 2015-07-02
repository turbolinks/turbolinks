class Turbolinks.View
  constructor: (@delegate) ->

  loadHTML: (html) ->
    {title, body} = parseHTML(html)
    loadTitle(title)
    loadBody(body)

  # Private

  loadTitle = (newTitleElement) ->
    document.title = newTitleElement.innerText if newTitleElement

  loadBody = (newBodyElement) ->
    document.body = newBodyElement

  parseHTML = (html) ->
    element = document.createElement("html")
    element.innerHTML = html
    title: element.querySelector("title")
    body: element.querySelector("body")

  removeElement = (element) ->
    element?.parentNode?.removeChild(element)
