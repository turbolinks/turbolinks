(function(eventNames) {
  window.eventLogs = []

  for (var i = 0; i < eventNames.length; i++) {
    var eventName = eventNames[i]
    addEventListener(eventName, eventListener, false)
  }

  function eventListener(event) {
    eventLogs.push([event.type, event.data])
  }

})([
  "turbolinks:before-cache",
  "turbolinks:before-render",
  "turbolinks:before-visit",
  "turbolinks:load",
  "turbolinks:render",
  "turbolinks:request-end",
  "turbolinks:visit"
])
