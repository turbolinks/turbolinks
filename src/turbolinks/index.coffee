#= require_self
#= require ./helpers
#= require ./controller

@Turbolinks =
  supported: true

  visit: (url) ->
    Turbolinks.controller.visit(url)
