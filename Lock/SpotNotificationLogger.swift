/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  SpotNotificationLogger.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 6/10/23.
//

import SwiftUI
import CoreData

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let eventType: LogEventType
    let spotName: String
    let message: String
    let userResponse: String?
}

enum LogEventType {
    case entered
    case exited
    case notificationSent
    case userResponse
    
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
    @Published var logs: [LogEntry] = []
    
    private init() {
        // Listen for notification responses
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationResponse),
            name: NSNotification.Name("NotificationResponse"),
            object: nil
        )
    }
    
    func addLog(eventType: LogEventType, spotName: String, message: String, userResponse: String? = nil) {
        DispatchQueue.main.async {
            let entry = LogEntry(
                timestamp: Date(),
                eventType: eventType,
                spotName: spotName,
                message: message,
                userResponse: userResponse
            )
            self.logs.insert(entry, at: 0) // Add to beginning for newest first
            
            // Keep only last 100 entries
            if self.logs.count > 100 {
                self.logs = Array(self.logs.prefix(100))
            }
        }
    }
    
    @objc private func handleNotificationResponse(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let response = userInfo["response"] as? String,
           let spotName = userInfo["spotName"] as? String {
            addLog(
                eventType: .userResponse,
                spotName: spotName,
                message: "User responded to notification",
                userResponse: response
            )
        }
    }
}

struct SpotNotificationLogger: View {
    @Environment(\.managedObjectContext) private var moc // Use environment context
    @EnvironmentObject private var locationManager: LocationDataManager // Use environment object
    @StateObject private var logManager = LogManager.shared // Add this line
    
    var body: some View {
        NavigationView {
            VStack {
                if logManager.logs.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No logs yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Geofence events and notification responses will appear here")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(logManager.logs) { log in
                        LogRowView(log: log)
                    }
                    .refreshable {
                        // Optional: Add refresh functionality
                    }
                }
            }
            .navigationTitle("Activity Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        logManager.logs.removeAll()
                    }
                    .disabled(logManager.logs.isEmpty)
                }
            }
            .onAppear {
                // Reset badge when user views the logs
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
}

struct LogRowView: View {
    let log: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: log.eventType.icon)
                    .foregroundColor(log.eventType.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(log.spotName)
                            .font(.headline)
                        Spacer()
                        Text(formatTime(log.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(log.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let response = log.userResponse {
                        HStack {
                            Image(systemName: "bubble.right.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text("Response: \(response)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct SpotNotificationLogger_Previews: PreviewProvider {
    static var previews: some View {
        SpotNotificationLogger()
    }
}
