//
//  HKSampleQueryDescriptor.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/16.
//
import SwiftUI
import HealthKit

struct HKSampleQueryDescriptorView: View {
    @State private var stepCount: Double = 0.0
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            Text("今日の歩数")
                .font(.largeTitle)
                .padding()
            Text("\(Int(stepCount))")
                .font(.title)
                .padding()
        }
        .onAppear {
            requestAuthorization()
        }
    }
    
    // HealthKitのアクセス許可をリクエストする関数
    private func requestAuthorization() {
        // 歩数データの型を指定
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("歩数データの型を取得できませんでした")
            return
        }
        
        // 読み書きの許可をリクエスト
        let typesToShare: Set = [stepCountType]
        let typesToRead: Set = [stepCountType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                // 許可が成功した場合、歩数データをフェッチ
                Task {
                    await fetchStepCountAndUpdateUI()
                }
            } else {
                // エラーハンドリング
                print("Authorization failed: \(error?.localizedDescription ?? "不明なエラー")")
            }
        }
    }
    
    // 今日の歩数をフェッチしてUIを更新する関数
    private func fetchStepCountAndUpdateUI() async {
        do {
            let samples = try await fetchStepCount()
            let totalSteps = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .count()) }
            DispatchQueue.main.async {
                stepCount = totalSteps
            }
        } catch {
            // エラーハンドリング
            print("エラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    // 今日の歩数データをフェッチする関数
    private func fetchStepCount() async throws -> [HKQuantitySample] {
        // 歩数データの型を指定
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw NSError(domain: "HKErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "歩数データの型を取得できませんでした"])
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // HKSampleQueryDescriptorを使用してデータを取得
        let queryDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: stepCountType, predicate: predicate)],
            sortDescriptors:  [.init(\.startDate, order: .forward)],
            limit: HKObjectQueryNoLimit
        )
        
        // クエリの結果を取得
        let results = try await queryDescriptor.result(for: healthStore)
        
        return results
    }
}

struct HKSampleQueryDescriptorView_Previews: PreviewProvider {
    static var previews: some View {
        HKSampleQueryDescriptorView()
    }
}
