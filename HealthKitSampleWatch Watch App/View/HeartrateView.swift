//
//  HeartrateView.swift
//  HealthKitSampleWatch Watch App
//
//  Created by ryo muranaka on 2024/05/15.
//

import SwiftUI
import UserNotifications

struct HeartrateView: View {
    @State private var trigger = false
    @ObservedObject var healthKitManager = HealthData()
    
    var body: some View {
        VStack {
            Text(String(format: "%.0f BPM", healthKitManager.heartRate))
                .font(.largeTitle)
                .bold()
            Text("Updated: \(formattedDate(healthKitManager.heartRateDate))")
                            .font(.caption)
            Button {
                healthKitManager.startHeartRateQuery()
            } label: {
                Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
            }

        }.onAppear{
            requestAuthorizationNotification()
        }
    }
    private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        }
    func sendNotification() {
            let content = UNMutableNotificationContent()
            content.title = "High Heart Rate Alert"
            content.body = "Your heart rate is above  bpm."

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "HighHeartRateNotification", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("Error sending notification: \(error.localizedDescription)")
                }
            }
        }
    
    private func requestAuthorizationNotification() {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: .alert) { granted, error in
                if granted {
                    print("許可されました！")
                }else{
                    print("拒否されました...")
                }
            }
        }
}

#Preview {
    HeartrateView()
}
