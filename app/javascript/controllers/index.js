import { Application } from "@hotwired/stimulus"
import TrackingController from "./tracking_controller"

const application = Application.start()
application.register("tracking", TrackingController)

// Import and register all your controllers from the importmap via controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
