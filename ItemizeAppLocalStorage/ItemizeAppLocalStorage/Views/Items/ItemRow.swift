//
//  ItemRow.swift
//  ItemizeAppLocalStorage
//
//  Created by Batiste Vancoillie on 27/10/2025.
//

// File: Views/Items/ItemRow.swift
import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Thumbnail (fallback icon als er geen foto is)
            if let filename = item.primaryImage?.filename, let ui = ImageStore.loadImage(named: filename) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.tealGreen.opacity(0.12), lineWidth: 1)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemFill))
                    Image(systemName: "shippingbox")
                        .imageScale(.medium)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 46, height: 46)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Titel + (optionele) categorie-chip op dezelfde regel met ruimte
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let cat = item.category {
                        Text(cat.name)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.sandBeige.opacity(0.6))
                            )
                            .overlay(
                                Capsule().stroke(Color.deepGreen.opacity(0.15), lineWidth: 1)
                            )
                            .foregroundStyle(Color.deepGreen)
                    }
                }

                if !item.fields.isEmpty {
                    Text(item.fields.map { "\($0.key): \($0.value)" }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Aantal als kleine chip
            Text("×\(item.quantity)")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.paleCream)
                )
                .overlay(
                    Capsule().stroke(Color.tealGreen.opacity(0.18), lineWidth: 1)
                )
                .foregroundStyle(Color.deepGreen)

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.yellow)
                    .padding(.leading, 4)
                    .accessibilityLabel(Text("Favoriet"))
            }
        }
        .padding(.vertical, 8)
    }
}
