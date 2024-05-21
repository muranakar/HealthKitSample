//
//  5_.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/17.
//

import SwiftUI
import HealthKit

// メインのビュー
struct HKCorrelationQueryView: View {
    @StateObject private var viewModel = HighCalorieFoodsViewModel()
    
    var body: some View {
        VStack {
            // 高カロリー食品のリストを表示
            List(viewModel.highCalorieFoods) { food in
                VStack(alignment: .leading) {
                    Text(food.name)
                        .font(.headline)
                    Text("カロリー: \(food.calories, specifier: "%.0f") kcal")
                        .font(.subheadline)
                }
            }
            .navigationTitle("高カロリー食品")
            .onAppear {
                // HealthKitの認可をリクエスト
                HealthKitSetupAssistant.requestAuthorization { success, error in
                    if success {
                        viewModel.fetchHighCalorieFoods()
                    } else {
                        print("HealthKitの認可に失敗しました: \(String(describing: error?.localizedDescription))")
                    }
                }
            }
            // 高カロリー食品を保存するボタン
            Button("高カロリー食を保存") {
                viewModel.saveHighCalorieFood()
                viewModel.fetchHighCalorieFoods()
            }
            .frame(width: 200, height: 60)
        }
    }
}

// プレビュー用のコード
struct HighCalorieFoodsView_Previews: PreviewProvider {
    static var previews: some View {
        HKCorrelationQueryView()
    }
}

// 高カロリー食品を表す構造体
struct HighCalorieFood: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
}

// 高カロリー食品のビューモデル
class HighCalorieFoodsViewModel: ObservableObject {
    @Published var highCalorieFoods: [HighCalorieFood] = []
    private let healthStore = HKHealthStore()
    
    // 高カロリー食品を取得する関数
    func fetchHighCalorieFoods() {
        // 高カロリー食品を取得するための述語を設定
        let highCalorie = HKQuantity(unit: .kilocalorie(), doubleValue: 800.0)
        let greaterThanHighCalorie = HKQuery.predicateForQuantitySamples(with: .greaterThanOrEqualTo, quantity: highCalorie)
        let energyConsumed = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let samplePredicates = [energyConsumed: greaterThanHighCalorie]
        let foodType = HKCorrelationType.correlationType(forIdentifier: .food)!
        
        // 高カロリー食品を取得するためのクエリを作成
        let query = HKCorrelationQuery(type: foodType, predicate: nil, samplePredicates: samplePredicates) { [weak self] query, results, error in
            guard let self = self, let correlations = results, error == nil else {
                print("高カロリー食品の取得中にエラーが発生しました: \(String(describing: error))")
                return
            }
            // メインスレッドで値を更新する
            DispatchQueue.main.async {
                self.highCalorieFoods = correlations.compactMap { self.convertToHighCalorieFood(correlation: $0) }
            }
        }
        
        healthStore.execute(query)
    }
    
    // HKCorrelationをHighCalorieFoodに変換する関数
    private func convertToHighCalorieFood(correlation: HKCorrelation) -> HighCalorieFood? {
        // 食品の名前やカロリー情報を抽出
        guard let calorieSample = correlation.objects(for: .quantityType(forIdentifier: .dietaryEnergyConsumed)!).first as? HKQuantitySample else {
            return nil
        }
        
        let calories = calorieSample.quantity.doubleValue(for: .kilocalorie())
        let name = "食品項目" // ここに実際の名前を取得するロジックを追加
        
        return HighCalorieFood(name: name, calories: calories)
    }
    
    // 高カロリー食品を保存する関数
    func saveHighCalorieFood() {
        let dietaryEnergyConsumedType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let foodType = HKObjectType.correlationType(forIdentifier: .food)!
        
        // 栄養成分サンプルの作成
        let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: 850.0)
        let calorieSample = HKQuantitySample(
            type: dietaryEnergyConsumedType,
            quantity: calorieQuantity,
            start: Date(),
            end: Date()
        )
        
        // 他の栄養成分サンプルも同様に作成
        // 例：たんぱく質、炭水化物など
        
        // 食品コレレーションの作成
        let foodCorrelation = HKCorrelation(
            type: foodType,
            start: Date(),
            end: Date(),
            objects: [calorieSample]  // 他のサンプルも含める
        )
        
        // 食品コレレーションをHealthKitに保存
        healthStore.save(foodCorrelation) { success, error in
            if success {
                print("食品サンプルが正常に保存されました")
            } else {
                // エラーハンドリング
                print("食品サンプルの保存に失敗しました: \(String(describing: error))")
            }
        }
    }
}

// HealthKitのセットアップアシスタント
class HealthKitSetupAssistant {
    static let healthStore = HKHealthStore()
    
    // HealthKitの認可をリクエストする関数
    static func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        
        let readTypes = Set([
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ])
        
        let shareTypes = Set([
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ])
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes, completion: completion)
    }
}
