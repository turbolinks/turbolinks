import { Controller, VisitOptions } from "./controller"
import { Locatable } from "./location"
import { RootSelector } from "./root_selector"


const controller = new Controller

export default {
  get supported() {
    return Controller.supported
  },

  controller,

  visit(location: Locatable, options?: Partial<VisitOptions>) {
    controller.visit(location, options)
  },

  clearCache() {
    controller.clearCache()
  },

  setProgressBarDelay(delay: number) {
    controller.setProgressBarDelay(delay)
  },

  setRootSelector(selector: RootSelector) {
    controller.setRootSelector(selector)
  },

  start() {
    controller.start()
  }
}
