#= require ./head_details

class Turbolinks.Renderer
  constructor: (@currentSnapshot, @newSnapshot) ->
    @currentHeadDetails = new Turbolinks.HeadDetails @currentSnapshot.head
    @newHeadDetails = new Turbolinks.HeadDetails @newSnapshot.head
    @newBody = @newSnapshot.body.cloneNode(true)

  render: (callback) ->
    if @trackedElementsAreIdentical()
      @mergeHead()
      @renderView =>
        @replaceBody()
        @focusFirstAutofocusableElement()
        callback()
    else
      @invalidateView()

  trackedElementsAreIdentical: ->
    @currentHeadDetails.getTrackedElementSignature() is @newHeadDetails.getTrackedElementSignature()

  renderView: (callback) ->
    @delegate.viewWillRender(@newBody)
    callback()
    @delegate.viewRendered(@newBody)

  invalidateView: ->
    @delegate?.viewInvalidated()

  mergeHead: ->
    @copyNewHeadStylesheetElements()
    @copyNewHeadScriptElements()
    @removeCurrentHeadProvisionalElements()
    @copyNewHeadProvisionalElements()

  replaceBody: (callback) ->
    @importBodyPermanentElements()
    @activateBodyScriptElements()
    @assignNewBody()

  copyNewHeadStylesheetElements: ->
    for element in @getNewHeadStylesheetElements()
      document.head.appendChild(element.cloneNode(true))

  copyNewHeadScriptElements: ->
    for element in @getNewHeadScriptElements()
      document.head.appendChild(activateScriptElement(element))

  removeCurrentHeadProvisionalElements: ->
    for element in @getCurrentHeadProvisionalElements()
      document.head.removeChild(element)

  copyNewHeadProvisionalElements: ->
    for element in @getNewHeadProvisionalElements()
      document.head.appendChild(element.cloneNode(true))

  importBodyPermanentElements: ->
    for replaceableElement in @getNewBodyPermanentElements()
      if element = @findCurrentBodyPermanentElement(replaceableElement)
        replaceableElement.parentNode.replaceChild(element, replaceableElement)

  activateBodyScriptElements: ->
    for replaceableElement in @getNewBodyScriptElements()
      element = activateScriptElement(replaceableElement)
      replaceableElement.parentNode.replaceChild(element, replaceableElement)

  assignNewBody: ->
    document.body = @newBody

  focusFirstAutofocusableElement: ->
    @findFirstAutofocusableElement()?.focus()

  getNewHeadStylesheetElements: ->
    @newHeadDetails.getStylesheetElementsNotInDetails(@currentHeadDetails)

  getNewHeadScriptElements: ->
    @newHeadDetails.getScriptElementsNotInDetails(@currentHeadDetails)

  getCurrentHeadProvisionalElements: ->
    @currentHeadDetails.getProvisionalElements()

  getNewHeadProvisionalElements: ->
    @newHeadDetails.getProvisionalElements()

  getNewBodyPermanentElements: ->
    @newBody.querySelectorAll("[id][data-turbolinks-permanent]")

  findCurrentBodyPermanentElement: (element) ->
    document.body.querySelector("##{element.id}[data-turbolinks-permanent]")

  getNewBodyScriptElements: ->
    @newBody.querySelectorAll("script")

  findFirstAutofocusableElement: ->
    document.body.querySelector("[autofocus]")

  activateScriptElement = (element) ->
    activatedScriptElement = document.createElement("script")
    activatedScriptElement.textContent = element.textContent
    copyElementAttributes(activatedScriptElement, element)
    activatedScriptElement

  copyElementAttributes = (destinationElement, sourceElement) ->
    for {name, value} in sourceElement.attributes
      destinationElement.setAttribute(name, value)
