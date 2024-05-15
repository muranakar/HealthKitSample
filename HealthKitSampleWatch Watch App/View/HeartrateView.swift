//
//  HeartrateView.swift
//  HealthKitSampleWatch Watch App
//
//  Created by ryo muranaka on 2024/05/15.
//

import SwiftUI

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

        }
    }
    private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        }
}

#Preview {
    HeartrateView()
}
