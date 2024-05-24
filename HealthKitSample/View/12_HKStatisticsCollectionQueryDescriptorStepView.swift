//
//  HKStatisticsCollectionQueryDescriptorStepView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/24.
//

import SwiftUI
import HealthKit

fileprivate class HealthStoreManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    func requestAuthorization() async throws {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        try await healthStore.requestAuthorization(toShare: [], read: [stepType])
    }
}

fileprivate struct AddStepsView: View {
    @State private var steps: String = ""
    let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            TextField("歩数を入力", text: $steps)
                .keyboardType(.numberPad)
                .padding()
            
            Button("歩数を追加") {
                if let stepCount = Double(steps) {
                    addSteps(stepCount)
                }
            }
            .padding()
        }
    }
    
    fileprivate func addSteps(_ steps: Double) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let quantity = HKQuantity(unit: .count(), doubleValue: steps)
        let now = Date()
        let sample = HKQuantitySample(type: stepType, quantity: quantity, start: now, end: now)
        
        healthStore.save(sample) { success, error in
            if success {
                print("歩数を追加しました")
            } else {
                print("エラー: \(String(describing: error))")
            }
        }
    }
}

fileprivate struct StepsView: View {
    @State private var steps: [HKStatistics] = []
    @State private var updateTask: Task<Void, Never>? = nil
    let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            List(steps, id: \.startDate) { statistic in
                HStack {
                    Text("\(statistic.startDate, formatter: dateFormatter)")
                    Spacer()
                    Text("\(statistic.sumQuantity()?.doubleValue(for: .count()) ?? 0, specifier: "%.0f") 歩")
                }
            }
            .onAppear {
                startQuery()
            }
            .onDisappear {
                updateTask?.cancel()
            }
        }
    }
    
    fileprivate func startQuery() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: today),
              let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return
        }
        
        let thisWeek = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let stepType = HKQuantityType(.stepCount)
        let stepsThisWeek = HKSamplePredicate.quantitySample(type: stepType, predicate: thisWeek)
        let everyDay = DateComponents(day: 1)
        
        let sumOfStepsQuery = HKStatisticsCollectionQueryDescriptor(
            predicate: stepsThisWeek,
            options: .cumulativeSum,
            anchorDate: endDate,
            intervalComponents: everyDay
        )
        Task {
            do {
                let stepCounts = try await sumOfStepsQuery.result(for: healthStore)
                DispatchQueue.main.async {
                    self.steps = stepCounts.statistics()
                }
            } catch {
                
            }
        }
        
        updateTask = Task {
            do {
                let updateQueue = sumOfStepsQuery.results(for: healthStore)
                DispatchQueue.main.async {
//                    self.steps = updateQueue.statistics()
                }
            } catch {
                print("エラー: \(error)")
            }
        }
    }
    
    fileprivate var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

struct HKStatisticsCollectionQueryDescriptorStepView: View {
    var body: some View {
        TabView {
            AddStepsView()
                .tabItem {
                    Label("歩数追加", systemImage: "plus.circle")
                }
            
            StepsView()
                .tabItem {
                    Label("歩数表示", systemImage: "list.bullet")
                }
        }
    }
}


#Preview {
    HKStatisticsCollectionQueryDescriptorStepView()
}
