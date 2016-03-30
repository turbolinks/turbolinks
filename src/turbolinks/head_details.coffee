class Turbolinks.HeadDetails
  constructor: (@element) ->
    @elements = {}
    for element in @element.childNodes when element.nodeType is Node.ELEMENT_NODE
      key = element.outerHTML
      data = @elements[key] ?=
        type: elementType(element)
        tracked: elementIsTracked(element)
        elements: []
      data.elements.push(element)

  hasElementWithKey: (key) ->
    key of @elements

  getTrackedElementSignature: ->
    (key for key, {tracked} of @elements when tracked).join("")

  getScriptElementsNotInDetails: (headDetails) ->
    @getElementsMatchingTypeNotInDetails("script", headDetails)

  getStylesheetElementsNotInDetails: (headDetails) ->
    @getElementsMatchingTypeNotInDetails("stylesheet", headDetails)

  getElementsMatchingTypeNotInDetails: (matchedType, headDetails) ->
    elements[0] for key, {type, elements} of @elements when type is matchedType and not headDetails.hasElementWithKey(key)

  getProvisionalElements: ->
    provisionalElements = []
    for key, {type, tracked, elements} of @elements
      if not type? and not tracked
        provisionalElements.push(elements...)
      else if elements.length > 1
        provisionalElements.push(elements[1...]...)
    provisionalElements

  elementType = (element) ->
    if elementIsScript(element)
      "script"
    else if elementIsStylesheet(element)
      "stylesheet"

  elementIsTracked = (element) ->
    element.getAttribute("data-turbolinks-track") is "reload"

  elementIsScript = (element) ->
    tagName = element.tagName.toLowerCase()
    tagName is "script"

  elementIsStylesheet = (element) ->
    tagName = element.tagName.toLowerCase()
    tagName is "style" or (tagName is "link" and element.getAttribute("rel") is "stylesheet")
