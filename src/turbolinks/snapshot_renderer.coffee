#= require ./renderer

class Turbolinks.SnapshotRenderer extends Turbolinks.Renderer
  constructor: (@currentSnapshot, @newSnapshot, @isPreview) ->
    @currentHeadDetails = @currentSnapshot.headDetails
    @newHeadDetails = @newSnapshot.headDetails
    @newBody = @newSnapshot.bodyElement

  render: (callback) ->
    if @shouldRender()
      @mergeHead()
      @renderView =>
        @replaceBody()
        @focusFirstAutofocusableElement() unless @isPreview
        callback()
    else
      @invalidateView()

  mergeHead: ->
    @copyNewHeadStylesheetElements()
    @copyNewHeadScriptElements()
    @removeCurrentHeadProvisionalElements()
    @copyNewHeadProvisionalElements()

  replaceBody: ->
    @activateBodyScriptElements()
    @importBodyPermanentElements()
    @assignNewBody()

  shouldRender: ->
    @newSnapshot.isVisitable() and @trackedElementsAreIdentical()

  trackedElementsAreIdentical: ->
    @currentHeadDetails.getTrackedElementSignature() is @newHeadDetails.getTrackedElementSignature()

  copyNewHeadStylesheetElements: ->
    for element in @getNewHeadStylesheetElements()
      document.head.appendChild(element)

  copyNewHeadScriptElements: ->
    for element in @getNewHeadScriptElements()
      document.head.appendChild(@createScriptElement(element))

  removeCurrentHeadProvisionalElements: ->
    for element in @getCurrentHeadProvisionalElements()
      document.head.removeChild(element)

  copyNewHeadProvisionalElements: ->
    for element in @getNewHeadProvisionalElements()
      document.head.appendChild(element)

  importBodyPermanentElements: ->
    for replaceableElement in @getNewBodyPermanentElements()
      if permanentElement = @findCurrentBodyPermanentElement(replaceableElement)
        importPermanentElement(permanentElement, replaceableElement)

  activateBodyScriptElements: ->
    for replaceableElement in @getNewBodyScriptElements()
      element = @createScriptElement(replaceableElement)
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

  importPermanentElement = (permanentElement, replaceableElement) ->
    permanentElement.parentNode.replaceChild(permanentElement.cloneNode(true), permanentElement)
    replaceableElement.parentNode.replaceChild(permanentElement, replaceableElement)
    permanentElement
