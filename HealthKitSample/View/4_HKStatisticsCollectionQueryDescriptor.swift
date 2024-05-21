//
//  HKStatisticsCollectionQueryDescriptor.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/17.
//

import SwiftUI
import HealthKit

// メインのビュー
struct HKStatisticsCollectionQueryDescriptorView: View {
    @State private var stepCounts: [Date: Double] = [:]
    
    var body: some View {
        VStack {
            Text("過去1週間の歩数")
                .font(.title)
                .padding()
            
            // 歩数をリスト表示
            List(stepCounts.sorted(by: { $0.key < $1.key }), id: \.key) { date, count in
                Text("\(date, formatter: dateFormatter): \(Int(count)) 歩")
            }
        }
        .onAppear {
            fetchStepCounts { stepCounts in
                self.stepCounts = stepCounts
                print("取得した歩数: \(stepCounts)") // 日本語のログを追加
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // 歩数データを取得する関数
    private func fetchStepCounts(completion: @escaping ([Date: Double]) -> Void) {
        let store = HKHealthStore()
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("歩数タイプが利用できません")
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) else {
            fatalError("開始日時の計算に失敗しました")
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                                 quantitySamplePredicate: predicate,
                                                 options: .cumulativeSum,
                                                 anchorDate: startDate,
                                                 intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                fatalError("初期結果の取得に失敗しました: \(String(describing: error))")
            }
            
            var stepCounts: [Date: Double] = [:]
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                let date = statistics.startDate
                let count = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                stepCounts[date] = count
                print("日付: \(date), 歩数: \(count)") // 日本語のログを追加
            }
            
            DispatchQueue.main.async {
                completion(stepCounts)
            }
        }
        
        store.execute(query)
    }
}

// プレビュー用のコード
struct HKStatisticsCollectionQueryDescriptorView_Previews: PreviewProvider {
    static var previews: some View {
        HKStatisticsCollectionQueryDescriptorView()
    }
}
