import { unindent } from "./util"

(() => {
  let element: Element | null = document.currentScript
  if (!element) return
  if (element.hasAttribute("data-turbolinks-suppress-warning")) return

  while (element = element.parentElement) {
    if (element == document.body) {
      return console.warn(unindent`
        You are loading Turbolinks from a <script> element inside the <body> element. This is probably not what you meant to do!

        Load your application’s JavaScript bundle inside the <head> element instead. <script> elements in <body> are evaluated with each page change.

        For more information, see: https://github.com/turbolinks/turbolinks#working-with-script-elements

        ——
        Suppress this warning by adding a "data-turbolinks-suppress-warning" attribute to: %s
      `, element.outerHTML)
    }
  }
})()
