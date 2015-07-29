#= require_self
#= require turbolinks/helpers
#= require turbolinks/controller

@Turbolinks =
  supported: true

  visit: (url) ->
    Turbolinks.controller.visit(url)
