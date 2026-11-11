import SwiftUI

struct CatalogView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Catalog",
                systemImage: "shippingbox",
                description: Text("Your products will appear here.")
            )
            .navigationTitle("Merchant Catalog")
        }
    }
}
