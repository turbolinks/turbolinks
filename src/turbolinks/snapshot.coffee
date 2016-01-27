#= require ./element_set

class Turbolinks.Snapshot
  @box: (snapshotOrHTML) ->
    if snapshotOrHTML instanceof this
      snapshotOrHTML
    else
      @fromHTML(snapshotOrHTML)

  @fromHTML: (html) ->
    element = document.createElement("html")
    element.innerHTML = html
    @fromElement(element)

  @fromElement: (element) ->
    new this
      head: element.querySelector("head")
      body: element.querySelector("body")

  constructor: ({head, body}) ->
    @head = head ? document.createElement("head")
    @body = body ? document.createElement("body")

  hasAnchor: (anchor) ->
    @body.querySelector("##{anchor}")?

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
    @trackedHeadElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("[data-turbolinks-track=reload]")

  getInlineHeadStyleElementSet: ->
    @inlineHeadStyleElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("style")

  getInlineHeadScriptElementSet: ->
    @inlineHeadScriptElementSet ?= @getPermanentHeadElementSet().selectElementsMatchingSelector("script:not([src])")

  getPermanentHeadElementSet: ->
    @permanentHeadElementSet ?= @getHeadElementSet().selectElementsMatchingSelector("script, style, link[href], [data-turbolinks-track=reload]")

  getTemporaryHeadElementSet: ->
    @temporaryHeadElementSet ?= @getHeadElementSet().getElementsNotPresentInSet(@getPermanentHeadElementSet())

  getHeadElementSet: ->
    @headElementSet ?= new Turbolinks.ElementSet @head.childNodes

