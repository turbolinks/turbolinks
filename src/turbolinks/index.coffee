#= require ./BANNER
#= require_self
#= require ./helpers
#= require ./controller

@Turbolinks =
  supported: true

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clearCache: ->
    Turbolinks.controller.clearCache()
