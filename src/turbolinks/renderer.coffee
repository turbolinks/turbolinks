class Turbolinks.Renderer
  @render: (delegate, callback, args...) ->
    renderer = new this args...
    renderer.delegate = delegate
    renderer.render(callback)
    renderer

  renderView: (callback) ->
    @delegate.viewWillRender(@newBody)
    callback()
    @delegate.viewRendered(@newBody)

  invalidateView: ->
    @delegate.viewInvalidated()

  cloneScriptElement: (element) ->
    if element.getAttribute("data-turbolinks-eval") is "false"
      element.cloneNode(true)
    else
      clonedScriptElement = document.createElement("script")
      clonedScriptElement.textContent = element.textContent
      copyElementAttributes(clonedScriptElement, element)
      clonedScriptElement

  copyElementAttributes = (destinationElement, sourceElement) ->
    for {name, value} in sourceElement.attributes
      destinationElement.setAttribute(name, value)
