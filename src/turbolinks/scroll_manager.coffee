class Turbolinks.ScrollManager
  start: ->
    unless @started
      addEventListener("scroll", @onScroll, false)
      @started = true
    
  stop: ->
    if @started
      removeEventListener("scroll", @onScroll, false)
      @started = false
  
  scrollToElement: (element) ->
    element.scrollIntoView()
  
  scrollToPosition: (x, y) ->
    window.scrollTo(x, y)

  onScroll: (event) =>
