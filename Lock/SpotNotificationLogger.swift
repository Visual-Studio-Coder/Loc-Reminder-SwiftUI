/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  SpotNotificationLogger.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/10/23.
//

import SwiftUI
import CoreData

enum LogEventType: String, CaseIterable {
    case entered = "regionEntered"
    case exited = "regionExited" 
    case notificationSent = "notificationSent"
    case userResponse = "userResponse"
    
    var icon: String {
        switch self {
        case .entered: return "arrow.down.circle.fill"
        case .exited: return "arrow.up.circle.fill"
        case .notificationSent: return "bell.fill"
        case .userResponse: return "person.fill.checkmark"
        }
    }
    
    var color: Color {
        switch self {
        case .entered: return .green
        case .exited: return .orange
        case .notificationSent: return .blue
        case .userResponse: return .purple
        }
    }
}

class LogManager: ObservableObject {
    static let shared = LogManager()
    private var managedObjectContext: NSManagedObjectContext?
    
    private init() {}
    
    func setManagedObjectContext(_ context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    func addLog(eventType: LogEventType, spotName: String, message: String) {
        // Always use main queue and handle both foreground and background
        DispatchQueue.main.async { [weak self] in
            self?.performLogSave(eventType: eventType, spotName: spotName, message: message)
        }
    }
    
    private func performLogSave(eventType: LogEventType, spotName: String, message: String) {
        guard let context = managedObjectContext else {
            print("❌ LogManager: No managed object context available")
            // Try to get context from DataController as fallback
            let dataController = DataController()
            let context = dataController.container.viewContext
            
            let logEntry = NSEntityDescription.entity(forEntityName: "LogEntry", in: context)!
            let newLog = NSManagedObject(entity: logEntry, insertInto: context)
            
            newLog.setValue(Date(), forKey: "timestamp")
            newLog.setValue(eventType.rawValue, forKey: "eventType")
            newLog.setValue(spotName, forKey: "spotName")
            newLog.setValue(message, forKey: "message")
            newLog.setValue(UUID(), forKey: "id")
            
            do {
                try context.save()
                print("✅ Log saved (fallback): \(eventType.rawValue) - \(spotName) - \(message)")
            } catch {
                print("❌ Failed to save log (fallback): \(error)")
            }
            return
        }
        
        // Create a new LogEntry Core Data entity
        let logEntry = NSEntityDescription.entity(forEntityName: "LogEntry", in: context)!
        let newLog = NSManagedObject(entity: logEntry, insertInto: context)
        
        newLog.setValue(Date(), forKey: "timestamp")
        newLog.setValue(eventType.rawValue, forKey: "eventType")
        newLog.setValue(spotName, forKey: "spotName")
        newLog.setValue(message, forKey: "message")
        newLog.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("✅ Log saved: \(eventType.rawValue) - \(spotName) - \(message)")
            
            // Post notification to refresh UI
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
        } catch {
            print("❌ Failed to save log: \(error)")
        }
    }
}

struct SpotNotificationLogger: View {
    @Environment(\.managedObjectContext) private var moc
    @EnvironmentObject private var locationManager: LocationDataManager
    @State private var logEntries: [NSManagedObject] = []
    
    var body: some View {
        NavigationView {
            List {
                if logEntries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Activity Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("Location-based notifications and user responses will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(logEntries, id: \.objectID) { logEntry in
                        LogEntryRow(logEntry: logEntry)
                    }
                    .onDelete(perform: deleteLogEntries)
                }
            }
            .navigationTitle("Activity Logs")
            .toolbar {
                if !logEntries.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            clearAllLogs()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .onAppear {
            LogManager.shared.setManagedObjectContext(moc)
            fetchLogEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            fetchLogEntries()
        }
    }
    
    private func fetchLogEntries() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "LogEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            logEntries = try moc.fetch(request)
        } catch {
            print("❌ Error fetching log entries: \(error)")
            logEntries = []
        }
    }
    
    private func deleteLogEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { logEntries[$0] }.forEach(moc.delete)
            
            do {
                try moc.save()
                fetchLogEntries()
            } catch {
                print("❌ Error deleting log entries: \(error)")
            }
        }
    }
    
    private func clearAllLogs() {
        withAnimation {
            logEntries.forEach(moc.delete)
            
            do {
                try moc.save()
                fetchLogEntries()
                print("✅ All logs cleared")
            } catch {
                print("❌ Error clearing logs: \(error)")
            }
        }
    }
}

struct LogEntryRow: View {
    let logEntry: NSManagedObject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: eventTypeIcon)
                    .foregroundColor(eventTypeColor)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(logEntry.value(forKey: "spotName") as? String ?? "Unknown Location")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatDate(logEntry.value(forKey: "timestamp") as? Date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(eventTypeDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let eventType = logEntry.value(forKey: "eventType") as? String,
               eventType == "userResponse",
               let message = logEntry.value(forKey: "message") as? String {
                HStack {
                    Spacer()
                    Text(message)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(responseColor.opacity(0.2))
                        )
                        .foregroundColor(responseColor)
                }
            } else if let message = logEntry.value(forKey: "message") as? String, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var eventTypeIcon: String {
        guard let eventType = logEntry.value(forKey: "eventType") as? String else { return "circle.fill" }
        
        switch eventType {
        case "regionEntered":
            return "arrow.right.circle.fill"
        case "regionExited":
            return "arrow.left.circle.fill"
        case "notificationSent":
            return "bell.fill"
        case "userResponse":
            return "bubble.right.fill"
        default:
            return "circle.fill"
        }
    }
    
    private var eventTypeColor: Color {
        guard let eventType = logEntry.value(forKey: "eventType") as? String else { return .gray }
        
        switch eventType {
        case "regionEntered":
            return .green
        case "regionExited":
            return .orange
        case "notificationSent":
            return .blue
        case "userResponse":
            return .purple
        default:
            return .gray
        }
    }
    
    private var eventTypeDescription: String {
        guard let eventType = logEntry.value(forKey: "eventType") as? String else { return "Unknown event" }
        
        switch eventType {
        case "regionEntered":
            return "Entered location"
        case "regionExited":
            return "Left location"
        case "notificationSent":
            return "Notification sent"
        case "userResponse":
            return "User response:"
        default:
            return eventType.capitalized
        }
    }
    
    private var responseColor: Color {
        guard let message = logEntry.value(forKey: "message") as? String else { return .gray }
        
        switch message.lowercased() {
        case "good":
            return .green
        case "not good":
            return .red
        case "edit":
            return .blue
        case "tapped":
            return .gray
        case "dismissed":
            return .orange
        default:
            return .purple
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "E h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: date)
    }
}

struct SpotNotificationLogger_Previews: PreviewProvider {
    static var previews: some View {
        SpotNotificationLogger()
    }
}
