//
//  9_.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/18.
//

import SwiftUI
import HealthKit

struct HKObserverQueryView: View {
    @State private var stepCount: Int = 0
    private var healthStore = HKHealthStore()

    var body: some View {
        VStack {
            Text("歩数: \(stepCount)")
                .font(.largeTitle)
                .padding()
        }
        .onAppear {
            startObservingStepCount()
        }
    }
    
    private func startObservingStepCount() {
        // ステップカウントのタイプオブジェクトを作成します
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** ステップカウントタイプを取得できません ***")
        }

        // Observerクエリを作成します
        let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) { (query, completionHandler, errorOrNil) in
            if let error = errorOrNil {
                // エラーを適切に処理します
                print("Observerクエリエラー: \(error.localizedDescription)")
                return
            }

            // 新しいデータを取得するために別のクエリを実行します
            fetchStepCount()
            
            // バックグラウンド更新の場合、completionHandlerを呼び出します
            completionHandler()
        }

        // クエリを実行します
        healthStore.execute(query)
        
        // バックグラウンドでの更新を有効にします
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .immediate) { success, error in
            if let error = error {
                print("バックグラウンド配信エラー: \(error.localizedDescription)")
                return
            }
            
            if success {
                print("バックグラウンド配信が有効になりました")
            }
        }
    }
    
    private func fetchStepCount() {
        // ステップカウントのタイプオブジェクトを作成します
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** ステップカウントタイプを取得できません ***")
        }

        // 今日の日付範囲を設定します
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // サンプルクエリを作成します
        let query = HKSampleQuery(sampleType: stepCountType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                // エラーを適切に処理します
                print("サンプルクエリエラー: \(error?.localizedDescription ?? "不明なエラー")")
                return
            }

            // ステップ数を計算します
            let totalSteps = samples.reduce(0) { $0 + $1.quantity.doubleValue(for: .count()) }

            // メインスレッドでUIを更新します
            DispatchQueue.main.async {
                self.stepCount = Int(totalSteps)
            }
        }

        // クエリを実行します
        healthStore.execute(query)
    }
}

