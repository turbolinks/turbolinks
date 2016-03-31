class Turbolinks.Renderer
  renderView: (callback) ->
    @delegate.viewWillRender(@newBody)
    callback()
    @delegate.viewRendered(@newBody)

  invalidateView: ->
    @delegate.viewInvalidated()

  activateScriptElement: (element) ->
    activatedScriptElement = document.createElement("script")
    activatedScriptElement.textContent = element.textContent
    copyElementAttributes(activatedScriptElement, element)
    activatedScriptElement

  copyElementAttributes = (destinationElement, sourceElement) ->
    for {name, value} in sourceElement.attributes
      destinationElement.setAttribute(name, value)
