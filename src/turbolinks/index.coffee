#= require ./BANNER
#= export Turbolinks
#= require_self
#= require ./helpers
#= require ./controller
#= require ./start

@Turbolinks =
  supported: do ->
    window.history.pushState? and
      window.requestAnimationFrame? and
      window.addEventListener?

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clearCache: ->
    Turbolinks.controller.clearCache()

  changeURL: (location) ->
    Turbolinks
      .controller
      .pushHistoryWithLocationAndRestorationIdentifier(location, Turbolinks.uuid())
