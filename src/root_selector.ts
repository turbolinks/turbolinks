export type RootSelector = string | undefined

export function assignBody(newBody: HTMLBodyElement, rootSelector: RootSelector) {
  if (rootSelector) {
    const oldRoot = document.body.querySelector(rootSelector)
    const newRoot = newBody.querySelector(rootSelector)

    if (oldRoot && newRoot) {
      const parent = oldRoot.parentElement
      if (parent) return parent.replaceChild(newRoot, oldRoot)
    }
  }

  document.body = newBody
}
