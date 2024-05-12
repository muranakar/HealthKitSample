//
//  StepCountSaveView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/08.
//

import SwiftUI
import HealthKit
import HealthKitUI


struct StepCountReadView: View {
    @StateObject var healthData = HealthData()
    @State var isSuccessRequest: Bool? = nil
    
    @State var list: [StepData] = []
    
    var body: some View {
        VStack{
            if isSuccessRequest == nil {
                Text("認証を行っておりません")
            }
            if isSuccessRequest == true {
                Text("認証に成功しました")
            }
            if isSuccessRequest == false {
                Text("認証に失敗しました")
            }
            
            Button("認証") {
                HealthData.requestHealthDataAccessIfNeeded { success in
                    if success {
                        isSuccessRequest = true
                    } else {
                        isSuccessRequest = false
                    }
                }
            }
            Button("データを取得する") {
                let now = Date()
                let startDate = getLastWeekStartDate()
                let endDate = now
                let dateInterval = DateComponents(day: 1)
                HealthData.fetchStatistics(with: .stepCount, options: .cumulativeSum, startDate: startDate, interval: dateInterval) { statisticsCollection in
                    statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                        let statisticsQuantity = getStatisticsQuantity(for: statistics, with: .cumulativeSum)
                        if let value = statisticsQuantity?.doubleValue(for: .count()) {
                            let stepData = StepData(stepCount: Int(value), startDate: statistics.startDate, endDate: statistics.endDate)
                            list.append(stepData)
                        }
                    }
                    let startDates = list.map { stepData in
                        stepData.startDate
                    }
                    let endDates = list.map { stepData in
                        stepData.endDate
                    }
                    let stepCounts = list.map { stepData in
                        stepData.stepCount
                    }
                    print(startDates)
                    print(endDates)
                    print(stepCounts)
                    
                }
            }   
        }
    }
        
        
}

#Preview {
    StepCountReadView()
}
