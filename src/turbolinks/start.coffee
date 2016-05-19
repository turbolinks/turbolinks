Turbolinks.start = ->
  if installTurbolinks()
    Turbolinks.controller ?= createController()
    Turbolinks.controller.start()

installTurbolinks = ->
  window.Turbolinks ?= Turbolinks
  window.Turbolinks is Turbolinks

createController = ->
  controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller

isModule = ->
  isCommonJSModule() or isAMDModule()

isCommonJSModule = ->
  typeof module is "object" and module.exports

isAMDModule = ->
  typeof define is "function" and define.amd

Turbolinks.start() unless isModule()
