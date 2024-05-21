//
//  5_1_HKCorrelationQueryView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/20.
//
// https://stackoverflow.com/questions/29073342/how-to-read-ios-healthkit-blood-pressure-systolic-diastolic-using-hkobserverqu

import SwiftUI
import HealthKit
import Charts

struct BloodPressureData: Identifiable {
    let id = UUID()
    let date: Date
    let systolic: Double
    let diastolic: Double
}

struct CorrelationQueryView: View {
    @State private var bloodPressureData: [BloodPressureData] = []
    @State private var systolicInput: String = ""
    @State private var diastolicInput: String = ""
    private var healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            Text("血圧グラフ")
                .font(.title)
            Chart {
                ForEach(bloodPressureData) { data in
                    LineMark(
                        x: .value("日付", data.date),
                        y: .value("最高血圧", data.systolic)
                    )
                    .foregroundStyle(by: .value("mmHg", "最高血圧"))
                    LineMark(
                        x: .value("日付", data.date),
                        y: .value("最低血圧", data.diastolic)
                    )
                    .foregroundStyle(by: .value("mmHg", "最低血圧"))
                }
            }
            .chartForegroundStyleScale(["最高血圧": Color.orange, "最低血圧": Color.cyan])
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
            
            HStack {
                TextField("最高血圧", text: $systolicInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                TextField("最低血圧", text: $diastolicInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                Button("保存") {
                    saveBloodPressureData()
                    hideKeyboard()
                }
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            requestAuthorization()
        }
    }
    
    private func requestAuthorization() {
        // HealthKitの許可をリクエスト
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!
        ]
        
        let typesToWrite: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if success {
                fetchBloodPressureData()
            } else {
                // 許可が得られなかった場合のエラーハンドリング
                print("HealthKitの許可が得られませんでした: \(String(describing: error))")
            }
        }
    }
    
    private func fetchBloodPressureData() {
        // 血圧データを取得
        let bloodPressureType = HKObjectType.correlationType(forIdentifier: .bloodPressure)!
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKCorrelationQuery(
            type: bloodPressureType,
            predicate: predicate,
            samplePredicates: nil
        ) { _, samples, error in
            guard let samples = samples else {
                // サンプルが取得できなかった場合のエラーハンドリング
                print("血圧データの取得に失敗しました: \(String(describing: error))")
                return
            }
            
            samples.forEach { sample in
                print(sample)
            }
            // 取得したデータを処理
            let fetchedData = samples.compactMap { sample -> BloodPressureData? in
                guard
                    let systolicSample = sample.objects(for: .quantityType(forIdentifier: .bloodPressureSystolic)! as HKSampleType).first as? HKQuantitySample,
                    let diastolicSample = sample.objects(for: .quantityType(forIdentifier: .bloodPressureDiastolic)! as HKSampleType).first as? HKQuantitySample
                else {
                    return nil
                }
                
                let systolic = systolicSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                let diastolic = diastolicSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                return BloodPressureData(date: sample.startDate, systolic: systolic, diastolic: diastolic)
            }
            
            DispatchQueue.main.async {
                self.bloodPressureData = fetchedData
            }
        }
        
        healthStore.execute(query)
    }
    
    private func saveBloodPressureData() {
        // 入力された血圧データをHealthKitに保存
        guard let systolicValue = Double(systolicInput),
              let diastolicValue = Double(diastolicInput) else {
            print("血圧の入力が無効です")
            return
        }
        
        let systolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolicValue)
        let diastolicQuantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: diastolicValue)
        
        let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        
        let now = Date()
        let systolicSample = HKQuantitySample(type: systolicType, quantity: systolicQuantity, start: now, end: now)
        let diastolicSample = HKQuantitySample(type: diastolicType, quantity: diastolicQuantity, start: now, end: now)
        
        let bloodPressureCorrelation = HKCorrelation(type: HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!, start: now, end: now, objects: Set([systolicSample, diastolicSample]))
        
        healthStore.save(bloodPressureCorrelation) { success, error in
            if success {
                // データを再取得してUIを更新
                fetchBloodPressureData()
                // 入力フィールドをクリア
                systolicInput = ""
                diastolicInput = ""
            } else {
                // データ保存に失敗した場合のエラーハンドリング
                print("血圧データの保存に失敗しました: \(String(describing: error))")
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CorrelationQueryView_Previews: PreviewProvider {
    static var previews: some View {
        CorrelationQueryView()
    }
}
