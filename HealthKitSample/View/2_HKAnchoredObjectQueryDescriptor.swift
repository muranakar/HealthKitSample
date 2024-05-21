//
//  HKAnchoredObjectQueryDescriptor.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/16.
//

import Foundation
import SwiftUI
import HealthKit

struct HKAnchoredObjectQueryDescriptorView: View {
    // ステップ数データを保持する配列
    @State private var stepData: [HKQuantitySample] = []
    // HealthKitのクエリアンカー
    @State private var anchor: HKQueryAnchor? = nil
    // データ更新用のタスク
    @State private var updateTask: Task<Void, Never>? = nil
    // HealthKitストアインスタンス
    private var healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            // ステップデータを表示するリスト
            List(stepData, id: \.uuid) { sample in
                VStack {
                    Text("\(sample.quantity.doubleValue(for: .count())) steps")
                    Text("開始日: \(formattedDate(sample.startDate))")
                    Text("終了日: \(formattedDate(sample.endDate))")
                }
            }
            // ビューが表示された時の処理
            .onAppear {
                Task {
                    do {
                        // 初期データの読み取り
                        try await readInitialData()
                        // データ変更の監視開始
                        startMonitoring()
                    } catch {
                        // エラーハンドリング
                        print("初期データの読み取りエラー: \(error)")
                    }
                }
            }
        }
    }
    
    // 日付をフォーマットする関数
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // 初期データを読み取る関数
    private func readInitialData() async throws {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // 現在の日付を取得
        let calendar = Calendar.current
        let now = Date()
        
        // 今月の最初の日を計算
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components) else {
            throw NSError(domain: "DateError", code: 0, userInfo: nil)
        }
        
        // 今月の最後の日を計算
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        // 日付フィルタを作成
        let datePredicate = HKQuery.predicateForSamples(withStart: startOfMonth, end: endOfMonth, options: .strictStartDate)
        
        // クエリ記述子の作成
        let anchorDescriptor = HKAnchoredObjectQueryDescriptor(
            predicates: [.quantitySample(type: stepType, predicate: datePredicate)],
            anchor: anchor,
            limit: 100
        )
        
        // クエリ実行して結果を取得
        let results = try await anchorDescriptor.result(for: healthStore)
        
        // 新しいアンカーを保存
        anchor = results.newAnchor
        
        // 追加されたサンプルを保存
        stepData.append(contentsOf: results.addedSamples)
    }

    // データ変更を監視する関数
    private func startMonitoring() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // クエリ記述子の作成
        let anchorDescriptor = HKAnchoredObjectQueryDescriptor(
            predicates: [.quantitySample(type: stepType)],
            anchor: anchor
        )
        
        // 更新キューの取得
        let updateQueue = anchorDescriptor.results(for: healthStore)
        
        // 更新タスクの開始
        updateTask = Task {
            do {
                // データ変更があるたびに処理
                for try await update in updateQueue {
                    stepData.append(contentsOf: update.addedSamples)
                }
            } catch {
                // エラーハンドリング
                print("データ変更の監視エラー: \(error)")
            }
        }
    }
}
