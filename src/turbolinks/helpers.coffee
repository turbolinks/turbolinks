Turbolinks.closest = (element, selector) ->
  closest.call(element, selector)

closest = do ->
  html = document.documentElement
  html.closest ? (selector) ->
    node = this
    while node
      return node if node.nodeType is Node.ELEMENT_NODE and match.call(node, selector)
      node = node.parentNode


Turbolinks.match = (element, selector) ->
  match.call(element, selector)

match = do ->
  html = document.documentElement
  html.matchesSelector ? html.webkitMatchesSelector ? html.msMatchesSelector ? html.mozMatchesSelector
