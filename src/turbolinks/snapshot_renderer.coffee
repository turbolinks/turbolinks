#= require ./renderer

class Turbolinks.SnapshotRenderer extends Turbolinks.Renderer
  constructor: (@currentSnapshot, @newSnapshot, @isPreview) ->
    @currentHeadDetails = @currentSnapshot.headDetails
    @newHeadDetails = @newSnapshot.headDetails
    @currentBody = @currentSnapshot.bodyElement
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
    permanentElements = @extractCurrentBodyPermanentElements()
    @activateNewBodyScriptElements()
    @assignNewBody()
    @replaceNewBodyPermanentElements(permanentElements)
    @replacePlaceholdersForPermanentElements(permanentElements)

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

  extractCurrentBodyPermanentElements: ->
    for permanentElement in @getCurrentBodyPermanentElements() when @findNewBodyPermanentElementById(permanentElement.id)
      placeholder = createPlaceholderForPermanentElement(permanentElement)
      replaceElementWithElement(permanentElement, placeholder)
      permanentElement

  replaceNewBodyPermanentElements: (permanentElements) ->
    for permanentElement in permanentElements
      if newElement = @findNewBodyPermanentElementById(permanentElement.id)
        replaceElementWithElement(newElement, permanentElement)

  replacePlaceholdersForPermanentElements: (permanentElements) ->
    for permanentElement in permanentElements
      if placeholder = @findPlaceholderById(permanentElement.id)
        clonedElement = permanentElement.cloneNode(true)
        replaceElementWithElement(placeholder, clonedElement)

  activateNewBodyScriptElements: ->
    for inertScriptElement in @getNewBodyScriptElements()
      activatedScriptElement = @createScriptElement(inertScriptElement)
      replaceElementWithElement(inertScriptElement, activatedScriptElement)

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

  getCurrentBodyPermanentElements: ->
    @currentBody.querySelectorAll("[id][data-turbolinks-permanent]")

  findNewBodyPermanentElementById: (id) ->
    @newBody.querySelector("##{id}[data-turbolinks-permanent]")

  findPlaceholderById: (id) ->
    @currentBody.querySelector("meta[name=turbolinks-permanent-placeholder][content='#{id}']")

  getNewBodyScriptElements: ->
    @newBody.querySelectorAll("script")

  findFirstAutofocusableElement: ->
    @newBody.querySelector("[autofocus]")

createPlaceholderForPermanentElement = (permanentElement) ->
  placeholder = document.createElement("meta")
  placeholder.setAttribute("name", "turbolinks-permanent-placeholder")
  placeholder.setAttribute("content", permanentElement.id)
  placeholder

replaceElementWithElement = (fromElement, toElement) ->
  if parentElement = fromElement.parentNode
    parentElement.replaceChild(toElement, fromElement)
    toElement
