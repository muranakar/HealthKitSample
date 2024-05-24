import SwiftUI
import HealthKit

struct HealthKitSwiftConcurrencyView: View {
    let store = HKHealthStore()
    @State private var trigger = false
    @State private var log: [String] = []
    @State private var myAnchor: HKQueryAnchor? = nil
    @State private var myUpdateTask: Task<Void, Never>? = nil
    @State private var stepsCount: Int = 1
    @State private var savedSample: HKQuantitySample? = nil
    
    var body: some View {
        VStack {
            Text("HealthKitクエリログ")
                .font(.subheadline)
                .padding(5)
            
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(log, id: \.self) { entry in
                        Text("\(entry)")
                    }
                    Color.clear.id(log.count)
                }
                .onChange(of: log) {
                    withAnimation {
                        proxy.scrollTo(log.count)
                    }
                }
            }
            HStack {
                TextField("歩数を入力", value: $stepsCount, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()
                
                Button(action: {
                    saveStepCount()
                }) {
                    Text("歩数を保存")
                }
                .padding()
            }
            .padding(5)
            
            if savedSample != nil  {
                Button(action: {
                    removeStepCount()
                    savedSample = nil
                }) {
                    Text("歩数を削除")
                }
                .padding(5)
            }
            
            
            Button(action: {
                startOneShotQuery()
            }) {
                Text("onShotQueryを実行")
            }
            .padding(5)
            
            Button(action: {
                startLongRunningQuery()
            }) {
                Text("Long-Running Queriesを開始")
            }
            .padding(5)
            
            Button(action: {
                stopUpdates()
            }) {
                Text("Long-Running Queriesを停止")
            }
            .padding(5)
        }
        .healthDataAccessRequest(
            store: healthStore,
            shareTypes: [HKQuantityType(.stepCount)],
            readTypes: [HKQuantityType(.stepCount)],
            trigger: trigger,
            completion: { result in
                
            }
        )
        .onDisappear {
            stopUpdates()
        }
    }
    
    func saveStepCount() {
        let stepType = HKQuantityType(.stepCount)
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(stepsCount))
        let now = Date()
        let sample = HKQuantitySample(type: stepType, quantity: quantity, start: now, end: now)
        savedSample = sample
        
        store.save(sample) { success, error in
            if let error = error {
                log.append("保存エラー: \(error.localizedDescription)\n")
            } else if success {
                log.append("保存: \(stepsCount) 歩を保存しました。\n")
            } else {
                log.append("歩数の保存に失敗しました。\n")
            }
        }
    }
    
    func removeStepCount() {
        guard let savedSample = savedSample else { return  }
        store.delete(savedSample) { success, error in
            if let error = error {
                log.append("削除 -\(error.localizedDescription)\n")
            } else if success {
                log.append("削除: 保存した歩数を削除しました。\n")
            } else {
                log.append("歩数の削除に失敗しました。\n")
            }
        }
    }
    
    func startOneShotQuery() {
        let store = HKHealthStore()
        
        // 一週間前の日付を取得
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day = components.day! - 7
        let oneWeekAgo = calendar.date(from: components)
        
        // 過去一週間以内のすべての歩数サンプルに対する述語を作成
        let inLastWeek = HKQuery.predicateForSamples(withStart: oneWeekAgo,
                                                     end: nil,
                                                     options: [.strictStartDate])
        
        // クエリディスクリプタを作成
        let stepType = HKQuantityType(.stepCount)
        let anchorDescriptor = HKAnchoredObjectQueryDescriptor(
            predicates: [.quantitySample(type: stepType,predicate: inLastWeek)],
            anchor: myAnchor,
            limit: 100)
        
        // ワンショットクエリを実行
        Task {
            do {
                let results = try await anchorDescriptor.result(for: store)
                let addedSamples = results.addedSamples
                let deletedSamples = results.deletedObjects
                
                log.append("変更を検出 -OneShotQuery \(addedSamples.count) 件の新しい歩数サンプルが見つかりました。\n")
                log.append("変更を検出 -OneShotQuery \(deletedSamples.count) 件の削除された歩数サンプルが見つかりました。\n")
                
                myAnchor = results.newAnchor
            } catch {
                log.append("クエリエラー: \(error.localizedDescription)\n")
            }
        }
    }
    
    func startLongRunningQuery() {
        stopUpdates()
        
        let store = HKHealthStore()
        
        // 一週間前の日付を取得
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day = components.day! - 7
        let oneWeekAgo = calendar.date(from: components)
        
        // 過去一週間以内のすべての歩数サンプルに対する述語を作成
        let inLastWeek = HKQuery.predicateForSamples(withStart: oneWeekAgo,
                                                     end: nil,
                                                     options: [.strictStartDate])
        
        // クエリディスクリプタを作成
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let anchorDescriptor = HKAnchoredObjectQueryDescriptor(
            predicates: [.quantitySample(type: stepType,predicate: inLastWeek)],
            anchor: myAnchor,
            limit: HKObjectQueryNoLimit)
        
        // 長期間のクエリを開始
        let updateQueue = anchorDescriptor.results(for: store)
        myUpdateTask = Task {
            do {
                for try await results in updateQueue {
                    let addedSamples = results.addedSamples
                    let deletedSamples = results.deletedObjects
                    myAnchor = results.newAnchor
                    
                    log.append("変更を検出 -LongRunningQuery \(addedSamples.count) 件の新しい歩数サンプルが見つかりました。\n")
                    log.append("変更を検出 -LongRunningQuery \(deletedSamples.count) 件の削除された歩数サンプルが見つかりました。\n")
                }
            } catch {
                log.append("クエリエラー: \(error.localizedDescription)\n")
            }
        }
    }
    
    func stopUpdates() {
        myUpdateTask?.cancel()
        myUpdateTask = nil
    }
}

struct HealthKitSwiftConcurrencyView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitSwiftConcurrencyView()
    }
}
