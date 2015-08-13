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

  hasSameTrackedHeadElementsAsSnapshot: (snapshot) ->
    @getTrackedHeadElementSet().isEqualTo(snapshot.getTrackedHeadElementSet())

  getInlineHeadElementsNotPresentInSnapshot: (snapshot) ->
    inlineStyleElements = @getInlineHeadStyleElementSet().getElementsNotPresentInSet(snapshot.getInlineHeadStyleElementSet())
    inlineScriptElements = @getInlineHeadScriptElementSet().getElementsNotPresentInSet(snapshot.getInlineHeadScriptElementSet())
    inlineStyleElements.getElements().concat(inlineScriptElements.getElements())

  getTemporaryHeadElements: ->
    @getTemporaryHeadElementSet().getElements()

  # Private

  getTrackedHeadElementSet: ->
    @trackedHeadElementSet ?= @getHeadElementSet().selectElementsMatchingSelector("[data-turbolinks-track=reload]")

  getInlineHeadStyleElementSet: ->
    @inlineHeadStyleElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("style")

  getInlineHeadScriptElementSet: ->
    @inlineHeadScriptElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("script:not([src])")

  getPermanentHeadElementSet: ->
    @permanentHeadElementSet ?= @getHeadElementSet().selectElementsMatchingSelector("style, link[rel=stylesheet], script, [data-turbolinks-track=reload]")

  getTemporaryHeadElementSet: ->
    @temporaryHeadElementSet ?= @getHeadElementSet().getElementsNotPresentInSet(@getPermanentHeadElementSet())

  getHeadElementSet: ->
    @headElementSet ?= new Turbolinks.ElementSet @head.childNodes

