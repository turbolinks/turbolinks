#= require ./renderer

class Turbolinks.ErrorRenderer extends Turbolinks.Renderer
  constructor: (@html) ->

  render: (callback) ->
    @renderView =>
      @replaceDocumentHTML()
      @activateBodyScriptElements()
      callback()

  replaceDocumentHTML: ->
    document.documentElement.innerHTML = @html

  activateBodyScriptElements: ->
    for replaceableElement in @getScriptElements()
      element = @createScriptElement(replaceableElement)
      replaceableElement.parentNode.replaceChild(element, replaceableElement)

  getScriptElements: ->
    document.documentElement.querySelectorAll("script")
