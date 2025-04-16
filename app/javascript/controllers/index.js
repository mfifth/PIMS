import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
window.Stimulus = application

// Use absolute imports matching your importmap
// import InfiniteScrollController from "../controllers/infinite_scroll_controller.js"
// import InfiniteBatchScrollController from "../controllers/infinite_batch_scroll_controller.js"
// import BatchesController from '../controllers/batches_controller.js'
// import LookupController from "../controllers/lookup_controller.js"
// import InventoryController from '../controllers/inventory_controller.js'

// // Register with consistent naming
// application.register("infinite-scroll", InfiniteScrollController);
// application.register("batch", BatchesController);
// application.register("infinite-batch-scroll", InfiniteBatchScrollController);
// application.register("lookup", LookupController);
// application.register("inventory", InventoryController);
eagerLoadControllersFrom("controllers", application)