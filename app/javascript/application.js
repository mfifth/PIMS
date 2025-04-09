import { Application } from "@hotwired/stimulus";
import InfiniteScrollController from "./controllers/infinite_scroll_controller";
import BatchesController from './controllers/batches_controller';
import InfiniteBatchScrollController from "./controllers/infinite_batch_scroll_controller";
import SidebarController from "./controllers/sidebar_controller"
import * as Turbo from "@hotwired/turbo"

const application = Application.start();
window.Stimulus = application; // ✅ Expose for debugging
window.Turbo = Turbo

// Register controllers manually
application.register("infinite-batch-scroll", InfiniteBatchScrollController);
application.register("infinite-scroll", InfiniteScrollController);
application.register("batch", BatchesController);
application.register("sidebar", SidebarController)
