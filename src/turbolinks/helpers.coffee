Turbolinks.copyObject = (object) ->
  result = {}
  for key, value of object
    result[key] = value
  result


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
  event.data = data ? {}
  (target ? document).dispatchEvent(event)
  event


Turbolinks.match = (element, selector) ->
  match.call(element, selector)

match = do ->
  html = document.documentElement
  html.matchesSelector ? html.webkitMatchesSelector ? html.msMatchesSelector ? html.mozMatchesSelector


Turbolinks.uuid = ->
  result = ""
  for i in [1..36]
    if i in [9, 14, 19, 24]
      result += "-"
    else if i is 15
      result += "4"
    else if i is 20
      result += (Math.floor(Math.random() * 4) + 8).toString(16)
    else
      result += Math.floor(Math.random() * 15).toString(16)
  result
