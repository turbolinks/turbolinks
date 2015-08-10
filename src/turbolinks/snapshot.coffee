#= require turbolinks/element_set

class Turbolinks.Snapshot
  @fromHTML: (html) ->
    element = document.createElement("html")
    element.innerHTML = html
    new this
      head: element.querySelector("head")
      body: element.querySelector("body")

  constructor: ({head, body, scrollLeft, scrollTop}) ->
    @head = head
    @body = body
    @scrollLeft = scrollLeft ? 0
    @scrollTop = scrollTop ? 0

  hasSameRemoteHeadElementsAsSnapshot: (snapshot) ->
    @getRemoteHeadStyleElementSet().isEqualTo(snapshot.getRemoteHeadStyleElementSet()) and
      @getRemoteHeadScriptElementSet().isEqualTo(snapshot.getRemoteHeadScriptElementSet())

  getInlineHeadElementsNotPresentInSnapshot: (snapshot) ->
    inlineStyleElements = @getInlineHeadStyleElementSet().getElementsNotPresentInSet(snapshot.getInlineHeadStyleElementSet())
    inlineScriptElements = @getInlineHeadScriptElementSet().getElementsNotPresentInSet(snapshot.getInlineHeadScriptElementSet())
    inlineStyleElements.getElements().concat(inlineScriptElements.getElements())

  getTemporaryHeadElements: ->
    @getTemporaryHeadElementSet().getElements()

  getPermanentBodyElements: ->
    element for element in @body.querySelectorAll("[id][data-turbolinks-permanent]")

  # Private

  getInlineHeadStyleElementSet: ->
    @inlineHeadStyleElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("style")

  getRemoteHeadStyleElementSet: ->
    @remoteHeadStyleElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("link[rel=stylesheet]")

  getInlineHeadScriptElementSet: ->
    @inlineHeadScriptElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("script:not([src])")

  getRemoteHeadScriptElementSet: ->
    @remoteHeadScriptElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("script[src]")

  getPermanentHeadElementSet: ->
    @permanentHeadElementSet ?= @getHeadElementSet().selectElementsMatchingSelector("style, link[rel=stylesheet], script")

  getTemporaryHeadElementSet: ->
    @temporaryHeadElementSet ?= @getHeadElementSet().rejectElementsMatchingSelector("style, link[rel=stylesheet], script")

  getHeadElementSet: ->
    @headElementSet ?= new Turbolinks.ElementSet @head.childNodes

