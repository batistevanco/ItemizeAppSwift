//
//  CategoriesOverviewView.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//

// File: Views/Categories/CategoriesOverviewView.swift
import SwiftUI
import SwiftData

struct CategoriesOverviewView: View {
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Item.name) private var allItems: [Item]
    
    var grouped: [(Category?, [Item])] {
        let dict = Dictionary(grouping: allItems) { $0.category?.id ?? "none" }
        let order = categories.map { $0.id } + ["none"]
        return order.compactMap { key in
            let items = dict[key] ?? []
            if key == "none" {
                return (nil, items)
            } else if let cat = categories.first(where: {$0.id == key}) {
                return (cat, items)
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0?.id) { (cat, items) in
                    Section(cat?.name ?? "Zonder categorie") {
                        ForEach(items) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                ItemRow(item: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Per categorie")
        }
    }
}
