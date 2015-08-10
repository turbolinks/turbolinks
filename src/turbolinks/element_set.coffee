class Turbolinks.ElementSet
  constructor: (elements) ->
    @elements = for element in elements when element.nodeType is Node.ELEMENT_NODE
      element: element
      value: element.outerHTML

  hasElement: (element) ->
    @findElement(element)?

  findElement: (needleElement) ->
    @getElementIndex()[needleElement.outerHTML]

  selectElementsMatchingSelector: (selector) ->
    elements = (element for {element, value} in @elements when Turbolinks.match(element, selector))
    new @constructor elements

  rejectElementsMatchingSelector: (selector) ->
    elements = (element for {element, value} in @elements when not Turbolinks.match(element, selector))
    new @constructor elements

  getElementsNotPresentInSet: (elementSet) ->
    index = elementSet.getElementIndex()
    elements = (element for {element, value} in @elements when value not of index)
    new @constructor elements

  getElements: ->
    element for {element} in @elements

  getValues: ->
    value for {value} in @elements

  isEqualTo: (elementSet) ->
    @toString() is elementSet?.toString()

  toString: ->
    @getValues().join("")

  # Private

  getElementIndex: ->
    @elementIndex ?= (
      elementIndex = {}
      for {element, value} in @elements
        elementIndex[value] = element
      elementIndex
    )
