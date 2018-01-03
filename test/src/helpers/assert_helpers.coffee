# An element has been "scrolledTo" if its position from the top of the viewport is between -1 and 1 pixels.
QUnit.assert.scrolledTo = (element, message) ->
  positionFromTop = element.getBoundingClientRect().top
  @push(-1 < positionFromTop < 1, positionFromTop, '(-1, 1)', message)
