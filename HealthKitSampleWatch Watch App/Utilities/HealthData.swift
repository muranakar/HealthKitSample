//
//  HealthData.swift
//  HealthKitSampleWatch Watch App
//
//  Created by ryo muranaka on 2024/05/15.
//

import SwiftUI
import HealthKit
import HealthKitUI

class HealthData: ObservableObject {
    var healthStore = HKHealthStore()
    @Published var heartRate: Double = 0.0
    @Published var heartRateDate: Date = Date()
    
    static var readDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    static var shareDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    private static var allHealthDataTypes: [HKSampleType] {
        let typeIdentifiers: [String] = [
            HKQuantityTypeIdentifier.heartRate.rawValue
        ]
        
        return typeIdentifiers.compactMap { getSampleType(for: $0) }
    }
    
    init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let typesToShare: Set = [heartRateType]
        let typesToRead: Set = [heartRateType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if success {
                self.startHeartRateQuery()
            } else {
                print("Authorization failed")
            }
        }
    }
    
    // アンカーを保持するプロパティ
    private var anchor: HKQueryAnchor?
    
    func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            fatalError("Heart Rate Type is unavailable")
        }
        
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: anchor, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, newAnchor, error) in
            // アンカーを保存して後続のクエリに使用
            self.anchor = newAnchor
            self.process(samples: samples, unit: heartRateUnit)
        }
        
        query.updateHandler = { (query, samples, deletedObjects, newAnchor, error) in
            self.process(samples: samples, unit: heartRateUnit)
        }
        
        healthStore.execute(query)
    }
    
    private func process(samples: [HKSample]?, unit: HKUnit) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            return
        }
        
        // heartRateSamplesをstartDateでソート
        if let latestSample = heartRateSamples.sorted(by: { $0.startDate > $1.startDate }).first {
            let date = latestSample.startDate
            print("start", latestSample.startDate)
            print("end", latestSample.endDate)
            let heartRate = latestSample.quantity.doubleValue(for: unit)
            
            DispatchQueue.main.async {
                self.heartRate = heartRate
                self.heartRateDate = date
            }
        }
    }
}
