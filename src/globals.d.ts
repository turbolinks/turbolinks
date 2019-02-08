interface Node {
  // https://github.com/Microsoft/TypeScript/issues/283
  cloneNode(deep?: boolean): this
}

interface Window {
  Turbolinks: any
}
