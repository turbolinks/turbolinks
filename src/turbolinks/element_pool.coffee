class Turbolinks.ElementPool
  constructor: (elements = []) ->
    @elements = {}
    @storeElement(element) for element in elements

  storeElement: (element) ->
    key = @getKeyForElement(element)
    elements = @getElementsForKey(key)
    elements.push(element) unless element in elements

  retrieveMatchingElement: (element) ->
    key = @getKeyForElement(element)
    elements = @getElementsForKey(key)
    elements.shift()

  # Private

  getKeyForElement: (element) ->
    element.outerHTML

  getElementsForKey: (key) ->
    @elements[key] ?= []
