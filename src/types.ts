export type Action = "advance" | "replace" | "restore"

export function isAction(action: any): action is Action {
  return action == "advance" || action == "replace" || action == "restore"
}

export type Position = { x: number, y: number }
