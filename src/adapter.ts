import { Locatable } from "./location"
import { Action } from "./types"
import { Visit } from "./visit"

export interface Adapter {
  visitProposedToLocationWithAction(location: Locatable, action: Action): void
  visitStarted(visit: Visit): void
  visitCompleted(visit: Visit): void
  visitFailed(visit: Visit): void
  visitRequestStarted(visit: Visit): void
  visitRequestProgressed?(visit: Visit): void
  visitRequestCompleted(visit: Visit): void
  visitRequestFailedWithStatusCode(visit: Visit, statusCode: number): void
  visitRequestFinished(visit: Visit): void
  visitRendered(visit: Visit): void
  pageInvalidated(): void
}
