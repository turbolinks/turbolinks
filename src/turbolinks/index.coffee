#= require ./BANNER
#= require_self
#= require ./helpers
#= require ./controller

@Turbolinks =
  supported: do ->
    window.history.pushState? and window.requestAnimationFrame?

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clearCache: ->
    Turbolinks.controller.clearCache()
