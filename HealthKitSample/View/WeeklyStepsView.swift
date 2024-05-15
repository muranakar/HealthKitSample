//
//  WeeklyStepsView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/14.
//

import SwiftUI
import HealthKit

struct WeeklyStepsView: View {
    @StateObject private var viewModel = StepsViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.steps, id: \.startDate) { statistics in
                HStack {
                    Text(statistics.startDate, style: .date)
                    Spacer()
                    Text("\(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0, specifier: "%.0f") 歩")
                }
            }
            .navigationTitle("1週間の歩数")
            .onAppear {
                viewModel.requestAuthorization()
            }
        }
    }
}


class StepsViewModel: ObservableObject {
    @Published var steps: [HKStatistics] = []
    
    func requestAuthorization() {
        HealthData.requestHealthDataAccessIfNeeded { success in
                if success {
                    self.fetchWeeklySteps()
                }
        }
    }
    
    private func fetchWeeklySteps() {
        HealthData.fetchWeeklySteps { [weak self] statistics in
            DispatchQueue.main.async {
                self?.steps = statistics ?? []
            }
        }
    }
}


#Preview {
    WeeklyStepsView()
}
