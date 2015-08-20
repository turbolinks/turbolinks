Turbolinks.closest = (element, selector) ->
  closest.call(element, selector)

closest = do ->
  html = document.documentElement
  html.closest ? (selector) ->
    node = this
    while node
      return node if node.nodeType is Node.ELEMENT_NODE and match.call(node, selector)
      node = node.parentNode


Turbolinks.defer = (callback) ->
  setTimeout(callback, 1)


Turbolinks.dispatch = (eventName, {target, cancelable, data} = {}) ->
  event = document.createEvent("Events")
  event.initEvent(eventName, true, cancelable is true)
  event.data = data
  (target ? document).dispatchEvent(event)
  event


Turbolinks.match = (element, selector) ->
  match.call(element, selector)

match = do ->
  html = document.documentElement
  html.matchesSelector ? html.webkitMatchesSelector ? html.msMatchesSelector ? html.mozMatchesSelector
