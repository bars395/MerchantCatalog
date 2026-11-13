# Merchant Catalog

A small iPhone catalog for sellers who need to find a product, check its price and available stock, and confirm its SKU.

## Run

Open `MerchantCatalog.xcodeproj` in Xcode 27.2, choose the shared `MerchantCatalog` scheme and an iPhone Simulator, then build and run. The app fetches product data from the live DummyJSON products API, requesting the full product list with only the fields it displays. The first catalog load requires an internet connection. No API key, separate server, or local configuration is required. The project targets iOS 17.0.

## Tests

Tests use local fixtures to verify API responses and screen behavior without relying on live network requests; fixtures are not used by the running app. Coverage includes flow root installation and product selection, detail SKU copying and shared image state, ProductsService fixture loading, catalog retry after an offline failure, debounced SKU search and clear, and refresh with an active SKU filter.

## Decisions and limits

I chose MVVM with a Coordinator to keep screen state, dependencies, and navigation separate. The view models own screen state, while `CatalogFlow` builds screens using services from the dependency container and handles navigation through the router. For a two-screen app, keeping state and navigation directly in SwiftUI views would involve less setup and fewer types. The Coordinator and dependency container add boilerplate and indirection that aren't strictly necessary at this scale. I accepted that trade-off because the boundaries make screen behavior easier to test, navigation easier to follow, and future screens easier to add without coupling them to one another. Returning from details also preserves the list and its search query.

Both screens use SwiftUI, but I chose `UINavigationController` for navigation. The router can push a SwiftUI screen through `UIHostingController` or a UIKit view controller directly. `NavigationStack` would be a simpler, more idiomatic option for a SwiftUI-only app; using UIKit navigation instead means extra hosting and imperative routing code. I accepted that cost to keep the flow flexible if a future screen is easier to build in UIKit. Either approach would work for the current scope.

Rows show the SKU so a seller can distinguish similar products. Pulling down refreshes prices and stock with the current search still applied. If the request fails, the previous results stay visible and the seller can pull again. The first release downloads the selected product fields in one request and searches the loaded catalog by title and SKU. Loading every product keeps search local, but the first screen takes longer to appear as the catalog grows. The API does not supply a currency, so displayed prices assume USD. List rows and the detail screen share one observable product model carrying image state. The catalog view model starts image loads when rows appear and immediately on selection; the model stays passive. ImageService keeps an in-memory URL cache, and image failures leave product text and navigation available.

Next, I’d load the first page of products on launch and fetch more as the seller scrolls. Search should still find a product by title or SKU even if its page hasn’t loaded yet. Editing inventory and offline support are left for a later iteration. Inventory edits need reliable writes and conflict handling. Offline display needs freshness rules for price and stock.

## Measuring usefulness

If this shipped, I’d measure how often sellers open a product from the list and how long it takes to get there, separating visits with a search from visits spent browsing. To check whether sellers found the *right* product, I’d also ask a few merchants to find a specific SKU and report its stock, then record how many succeed and how long they take.

To judge whether the **Copy SKU** button earns its place, I’d compare detail visits with at least one copy against all detail visits where the button was available. A seller who opens a product, checks stock and leaves still completed a useful lookup. I’d track time to first display and catalog request failures alongside those measures.

## AI use

I used two Codex agents. The lead agent broke the brief into small commits and reviewed each change. A subagent running a smaller model implemented each step and addressed review comments. That helped me get to a working MVP quickly and catch mistakes early. I could step in for design decisions and save my own full code review for the end.

I gave the agents skills covering SwiftUI view composition, Swift concurrency, file organization and testing. I also supplied ImageFeedApp as an architecture reference and examples of how I write routers and coordinators. That gave the agents concrete patterns to follow without my having to repeat the same feedback on each screen. I still changed decisions that mattered to me. For example, I chose UIKit navigation over the proposed nested `NavigationStack` and asked for a Combine debounce on SKU search so the app could use the standard operator.
