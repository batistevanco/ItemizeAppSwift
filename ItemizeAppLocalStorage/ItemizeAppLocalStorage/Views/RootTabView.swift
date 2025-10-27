//
//  RootTabView.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//


// File: Views/RootTabView.swift
import SwiftUI

struct RootTabView: View {
    @AppStorage("appTheme") private var appTheme: Theme = .auto

    var body: some View {
        TabView {
            ItemListView()
                .tabItem { Label("Items", systemImage: "list.bullet") }
            CategoriesOverviewView()
                .tabItem { Label("Categorieën", systemImage: "square.grid.2x2") }
            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gear") }
        }.preferredColorScheme(appTheme == .auto ? nil
                               : (appTheme == .dark ? .dark : .light))
    }
}
