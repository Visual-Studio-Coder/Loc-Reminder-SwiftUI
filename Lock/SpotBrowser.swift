/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  SpotBrowser.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/10/23.
//

import SwiftUI

struct SpotBrowser: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Spots.nameOfLocation, ascending: true)]) var spots: FetchedResults<Spots>
    @State private var showingAddSpot = false
    @State private var searchText = ""
    
    var filteredSpots: [Spots] {
        if searchText.isEmpty {
            return Array(spots)
        } else {
            return spots.filter { spot in
                (spot.nameOfLocation?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (spot.address?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if filteredSpots.isEmpty {
                    if spots.isEmpty {
                        // No spots at all
                        VStack(spacing: 20) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Spots Yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Add your first location to get started with geofencing reminders")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button("Add Your First Spot") {
                                showingAddSpot = true
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // No search results
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Results")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("No spots match '\(searchText)'")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    List {
                        ForEach(filteredSpots, id: \.id) { spot in
                            SpotRowView(spot: spot)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        deleteSpot(spot)
                                    }
                                }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search spots...")
                }
            }
            .navigationTitle("My Spots")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        showingAddSpot = true
                    }
                }
            }
            .sheet(isPresented: $showingAddSpot) {
                AddSpotView()
            }
        }
    }
    
    private func deleteSpot(_ spot: Spots) {
        // Stop monitoring this region
        if let spotId = spot.id {
            let locationManager = LocationDataManager()
            for region in locationManager.locationManager.monitoredRegions {
                if region.identifier == spotId.uuidString {
                    locationManager.locationManager.stopMonitoring(for: region)
                    print("🗑️ Stopped monitoring region: \(spot.nameOfLocation ?? "Unknown")")
                    break
                }
            }
        }
        
        // Delete from Core Data
        moc.delete(spot)
        
        do {
            try moc.save()
            print("✅ Deleted spot: \(spot.nameOfLocation ?? "Unknown")")
        } catch {
            print("❌ Error deleting spot: \(error)")
        }
    }
}

struct SpotRowView: View {
    let spot: Spots
    @State private var showingEditView = false
    @StateObject private var locationManager = LocationDataManager()
    @Environment(\.managedObjectContext) var moc
    @State private var refreshTrigger = false
    
    var body: some View {
        Button {
            showingEditView = true
        } label: {
            HStack(spacing: 12) {
                // Location Icon with Status
                VStack {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: statusIcon)
                            .font(.title2)
                            .foregroundColor(statusColor)
                    }
                    
                    // Distance indicator
                    Text("\(Int(spot.distanceFromSpot))m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Main Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(spot.nameOfLocation ?? "Unnamed Location")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Notification type badge
                        HStack(spacing: 4) {
                            Image(systemName: spot.notifyOnBoth ? "bell.badge" : "bell")
                                .font(.caption)
                                .foregroundColor(spot.notifyOnBoth ? .blue : .orange)
                            
                            Text(spot.notifyOnBoth ? "Both" : "Exit Only")
                                .font(.caption2)
                                .foregroundColor(spot.notifyOnBoth ? .blue : .orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill((spot.notifyOnBoth ? Color.blue : Color.orange).opacity(0.1))
                        )
                    }
                    
                    // Address
                    if let address = spot.address, !address.isEmpty {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("No address")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    // Custom notification preview
                    if let title = spot.customNotificationTitle, !title.isEmpty {
                        HStack {
                            Image(systemName: "quote.bubble")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(title)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                        .padding(.top, 2)
                    }
                    
                    // Coordinates and status info
                    HStack {
                        // Coordinates
                        if spot.latitude != 0.0 && spot.longitude != 0.0 {
                            HStack(spacing: 2) {
                                Image(systemName: "location")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text(String(format: "%.4f, %.4f", spot.latitude, spot.longitude))
                                    .font(.caption2.monospaced())
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 2) {
                                Image(systemName: "location.slash")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                Text("Invalid coordinates")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        // Monitoring status
                        if isBeingMonitored {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Active")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        } else {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("Inactive")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                showingEditView = true
            } label: {
                Label("Edit Spot", systemImage: "pencil")
            }
            
            Divider()
            
            Button {
                UIPasteboard.general.string = spot.nameOfLocation ?? "Unnamed Location"
            } label: {
                Label("Copy Name", systemImage: "doc.on.doc")
            }
            
            if let address = spot.address, !address.isEmpty {
                Button {
                    UIPasteboard.general.string = address
                } label: {
                    Label("Copy Address", systemImage: "location")
                }
            }
            
            if spot.latitude != 0.0 && spot.longitude != 0.0 {
                Button {
                    let coordinates = String(format: "%.6f, %.6f", spot.latitude, spot.longitude)
                    UIPasteboard.general.string = coordinates
                } label: {
                    Label("Copy Coordinates", systemImage: "mappin")
                }
                
                Button {
                    let mapsURL = "https://maps.apple.com/?q=\(spot.latitude),\(spot.longitude)"
                    UIPasteboard.general.string = mapsURL
                } label: {
                    Label("Copy Maps Link", systemImage: "map")
                }
            }
            
            if let customTitle = spot.customNotificationTitle, !customTitle.isEmpty {
                Button {
                    UIPasteboard.general.string = customTitle
                } label: {
                    Label("Copy Notification Title", systemImage: "bell")
                }
            }
            
            if let customBody = spot.customNotificationBody, !customBody.isEmpty {
                Button {
                    UIPasteboard.general.string = customBody
                } label: {
                    Label("Copy Notification Body", systemImage: "text.bubble")
                }
            }
            
            Button {
                let spotInfo = """
                Name: \(spot.nameOfLocation ?? "Unnamed Location")
                Address: \(spot.address ?? "No address")
                Coordinates: \(String(format: "%.6f, %.6f", spot.latitude, spot.longitude))
                Radius: \(Int(spot.distanceFromSpot)) meters
                Notifications: \(spot.notifyOnBoth ? "Entry & Exit" : "Exit Only")
                Custom Title: \(spot.customNotificationTitle ?? "Default")
                Custom Body: \(spot.customNotificationBody ?? "Default")
                """
                UIPasteboard.general.string = spotInfo
            } label: {
                Label("Copy All Info", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive) {
                deleteSpot()
            } label: {
                Label("Delete Spot", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditSpotView(spot: spot)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            // Force view refresh when Core Data context saves
            refreshTrigger.toggle()
        }
        .id(refreshTrigger) // This will force the view to refresh when refreshTrigger changes
    }
    
    private func deleteSpot() {
        // Stop monitoring this region
        if let spotId = spot.id {
            for region in locationManager.locationManager.monitoredRegions {
                if region.identifier == spotId.uuidString {
                    locationManager.locationManager.stopMonitoring(for: region)
                    print("🗑️ Stopped monitoring region: \(spot.nameOfLocation ?? "Unknown")")
                    break
                }
            }
        }
        
        // Delete from Core Data
        moc.delete(spot)
        
        do {
            try moc.save()
            print("✅ Deleted spot: \(spot.nameOfLocation ?? "Unknown")")
        } catch {
            print("❌ Error deleting spot: \(error)")
        }
    }
    
    private var statusColor: Color {
        if spot.latitude == 0.0 && spot.longitude == 0.0 {
            return .red
        } else if isBeingMonitored {
            return .green
        } else {
            return .orange
        }
    }
    
    private var statusIcon: String {
        if spot.latitude == 0.0 && spot.longitude == 0.0 {
            return "exclamationmark.triangle.fill"
        } else if isBeingMonitored {
            return "mappin.circle.fill"
        } else {
            return "mappin.circle"
        }
    }
    
    private var isBeingMonitored: Bool {
        guard let spotId = spot.id else { return false }
        return locationManager.locationManager.monitoredRegions.contains { region in
            region.identifier == spotId.uuidString
        }
    }
}

struct SpotBrowser_Previews: PreviewProvider {
    static var previews: some View {
        SpotBrowser()
    }
}
