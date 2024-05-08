//
//  StepCountSaveView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/08.
//

import SwiftUI

struct StepCountSaveView: View {
    @StateObject var healthData = HealthData()
    @State var isSuccessRequest: Bool? = nil
    
    @State var list: [Double] = []
    
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
                            list.append(value)
                        }
                    }
                    print(list)
                }
            }
            
        }
    }
        
        
}

#Preview {
    StepCountSaveView()
}
