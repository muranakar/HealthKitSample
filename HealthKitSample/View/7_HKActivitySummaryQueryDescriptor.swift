//
//  7_.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/17.
//

//https://rryam.com/healthkit-activity-summary

import SwiftUI
import HealthKit
import SwiftUI
import HealthKit


struct HKActivitySummaryQueryDescriptorView: View {
    @StateObject private var viewModel = ActivitySummaryViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.summaries, id: \.self) { summary in
                VStack(alignment: .leading, spacing: 10) {
                    Text("ムーブモード: \(summary.activityMoveMode.rawValue)")
                    Text("アクティブエネルギー消費: \(summary.activeEnergyBurned.doubleValue(for: .kilocalorie())) kcal")
                    Text("アクティブエネルギー目標: \(summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())) kcal")
                    Text("ムーブ時間: \(summary.appleMoveTime.doubleValue(for: .minute())) 分")
                    Text("ムーブ時間目標: \(summary.appleMoveTimeGoal.doubleValue(for: .minute())) 分")
                    Text("エクササイズ時間: \(summary.appleExerciseTime.doubleValue(for: .minute())) 分")
                    Text("エクササイズ目標: \(summary.appleExerciseTimeGoal.doubleValue(for: .minute())) 分")
                    
                    if let exerciseTimeGoal = summary.exerciseTimeGoal {
                        Text("運動時間目標: \(exerciseTimeGoal.doubleValue(for: .minute())) 分")
                    }
                    
                    Text("スタンド: \(summary.appleStandHours.doubleValue(for: .count())) 回")
                    
                    if let standHoursGoal = summary.standHoursGoal {
                        Text("スタンド目標: \(standHoursGoal.doubleValue(for: .count())) 回")
                    }
                    
                    Text("スタンド目標: \(summary.appleStandHoursGoal.doubleValue(for: .count())) 回")
                }
            }
            .navigationTitle("Activity Summaries")
        }
    }
}


class ActivitySummaryViewModel: ObservableObject {
    private var healthStore = HKHealthStore()
    @Published var summaries: [HKActivitySummary] = []
    var updateTask: Task<Void, Never>? = nil
    var activeSummaryTask: Task<Void, Never>? = nil
    
    init() {
        requestAuthorization()
        
        
    }
    
    func requestAuthorization() {
        let readTypes: Set = [HKObjectType.activitySummaryType()]
        healthStore.requestAuthorization(toShare: [], read: readTypes) { (success, error) in
            if success {
                Task {
                    await self.fetchActivitySummaries()
                }
            }
        }
    }
    
    func fetchActivitySummaries() async {
        let calendar = Calendar(identifier: .gregorian)
        
        // 現在の日付を取得し、時間情報を含まない日付コンポーネントを作成
        var startComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        startComponents.calendar = calendar
        
        var endComponents = DateComponents()
        endComponents.calendar = calendar
        endComponents.year = startComponents.year
        endComponents.month = startComponents.month
        endComponents.day = (startComponents.day ?? 0) + 1
        
        let todayPredicate = HKQuery.predicate(forActivitySummariesBetweenStart: startComponents, end: endComponents)
        let descriptor = HKActivitySummaryQueryDescriptor(predicate: todayPredicate)
        
        // Run the query.
        do{
            let results = try await descriptor.result(for: healthStore)
            Task {
                summaries = results
            }
        } catch {
            
        }
        
        
        updateTask = Task {
            do {
                let updateQueue = descriptor.results(for: healthStore)
                for try await results in updateQueue {
                    DispatchQueue.main.async {
                        self.summaries = results
                    }
                }
            } catch {
                // エラーハンドリング
            }
        }
    }
}
