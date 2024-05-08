//
//  HealthData.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/08.
//

import Foundation
import HealthKit

class HealthData: ObservableObject {
    @Published var stepCount: Int = 0
    
    static let healthStore: HKHealthStore = HKHealthStore()
    
    // MARK: - Data Types
    
    static var readDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    static var shareDataTypes: [HKSampleType] {
        return allHealthDataTypes
    }
    
    private static var allHealthDataTypes: [HKSampleType] {
        let typeIdentifiers: [String] = [
            HKQuantityTypeIdentifier.stepCount.rawValue
        ]
        
        return typeIdentifiers.compactMap { getSampleType(for: $0) }
    }
    
    // MARK: - Authorization
    
    /// 必要に応じてHealthKitから健康データをリクエストします。`HealthData.allHealthDataTypes`内のデータを使用します。
    class func requestHealthDataAccessIfNeeded(dataTypes: [String]? = nil, completion: @escaping (_ success: Bool) -> Void) {
        var readDataTypes = Set(allHealthDataTypes)
        var shareDataTypes = Set(allHealthDataTypes)
        
        if let dataTypeIdentifiers = dataTypes {
            readDataTypes = Set(dataTypeIdentifiers.compactMap { getSampleType(for: $0) })
            shareDataTypes = readDataTypes
        }
        
        requestHealthDataAccessIfNeeded(toShare: shareDataTypes, read: readDataTypes, completion: completion)
    }

    /// 必要に応じてHealthKitからヘルスケアデータをリクエストします。
    class func requestHealthDataAccessIfNeeded(toShare shareTypes: Set<HKSampleType>?,
                                               read readTypes: Set<HKObjectType>?,
                                               completion: @escaping (_ success: Bool) -> Void) {
        if !HKHealthStore.isHealthDataAvailable() {
            fatalError("ヘルスケアデータを利用できません！")
        }
        
        print("HealthKitの認証をリクエストしています...")
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            if let error = error {
                print("認証リクエストのエラー:", error.localizedDescription)
            }
            
            if success {
                print("HealthKitの認証リクエストが成功しました！")
            } else {
                print("HealthKitの認証が失敗しました。")
            }
            
            completion(success)
        }
    }
    
    // MARK: - HKHealthStore
    
    class func saveHealthData(_ data: [HKObject], completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        healthStore.save(data, withCompletion: completion)
    }
    
    // MARK: - HKStatisticsCollectionQuery
    
    class func fetchStatistics(with identifier: HKQuantityTypeIdentifier,
                               predicate: NSPredicate? = nil,
                               options: HKStatisticsOptions,
                               startDate: Date,
                               endDate: Date = Date(),
                               interval: DateComponents,
                               completion: @escaping (HKStatisticsCollection) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            fatalError("*** Unable to create a step count type ***")
        }
        
        let anchorDate = createAnchorDate()
        
        // クエリを作成する
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: predicate,
                                                options: options,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        
        // 結果をハンドリングする
        query.initialResultsHandler = { query, results, error in
            if let statsCollection = results {
                completion(statsCollection)
            }
        }
         
        healthStore.execute(query)
    }
    
    // MARK: - Helper Functions
    
    class func updateAnchor(_ newAnchor: HKQueryAnchor?, from query: HKAnchoredObjectQuery) {
        if let sampleType = query.objectType as? HKSampleType {
            setAnchor(newAnchor, for: sampleType)
        } else {
            if let identifier = query.objectType?.identifier {
                print("anchoredObjectQueryDidUpdate error: Did not save anchor for \(identifier) – Not an HKSampleType.")
            } else {
                print("anchoredObjectQueryDidUpdate error: query doesn't not have non-nil objectType.")
            }
        }
    }
    
    private static let userDefaults = UserDefaults.standard
    
    private static let anchorKeyPrefix = "Anchor_"
    
    private class func anchorKey(for type: HKSampleType) -> String {
        return anchorKeyPrefix + type.identifier
    }
    
    /// Returns the saved anchor used in a long-running anchored object query for a particular sample type.
    /// Returns nil if a query has never been run.
    class func getAnchor(for type: HKSampleType) -> HKQueryAnchor? {
        if let anchorData = userDefaults.object(forKey: anchorKey(for: type)) as? Data {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: anchorData)
        }
        
        return nil
    }
    
    /// Update the saved anchor used in a long-running anchored object query for a particular sample type.
    private class func setAnchor(_ queryAnchor: HKQueryAnchor?, for type: HKSampleType) {
        if let queryAnchor = queryAnchor,
            let data = try? NSKeyedArchiver.archivedData(withRootObject: queryAnchor, requiringSecureCoding: true) {
            userDefaults.set(data, forKey: anchorKey(for: type))
        }
    }
}
