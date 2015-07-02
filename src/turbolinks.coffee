#= require_self
#= require turbolinks/helpers
#= require turbolinks/controller

@Turbolinks =
  visit: (url) ->
    Turbolinks.controller.visit(url)
