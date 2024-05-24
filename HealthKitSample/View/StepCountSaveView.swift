//
//  StepCountSaveView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/08.
//

import SwiftUI
import HealthKit
import Foundation


struct StepCountSaveView: View {
    
    struct StepData {
        var stepCount: Int
        var startDate: Date
        var endDate: Date
    }
    
    @StateObject var healthData = HealthData()
    @State private var authenticated: Bool? = nil
    @State private var trigger = false
    @State var isSuccessRequest: Bool? = nil
    @State var inputStepCount: Int = 0
    
    @State var list: [StepData] = []
    
    var body: some View {
        VStack(alignment: .center){
            Spacer()
            if authenticated == nil {
                Text("認証を行っておりません")
            }
            if authenticated == true {
                Text("認証に成功しました")
            }
            if authenticated == false {
                Text("認証に失敗しました")
            }
            
            TextField("",value: $inputStepCount, format: .number)
            
            Button("歩数を保存する") {
                guard let sample = processHealthSample(with: Double(inputStepCount)) else { return }
                HealthData.saveHealthData([sample]) { success, error in
                    if let error = error {
                        print("エラー:", error.localizedDescription)
                    }
                    if success {
                        print("新しいサンプルを正常に保存しました！", sample)
                    } else {
                        print("エラー: 新しいサンプルを保存できませんでした。", sample)
                    }
                }
            }
            Spacer()
        }.healthDataAccessRequest(
            store: HealthData.healthStore,
            shareTypes: Set(HealthData.shareDataTypes),
            readTypes: Set(HealthData.readDataTypes),
            trigger: trigger,
            completion: { result in
                switch result {
                case .success(_):
                    authenticated = true
                case .failure(let error):
                    // Handle the error here.
                    fatalError("*** An error occurred while requesting authentication: \(error) ***")
                }
            }
        )
        .onAppear{
            trigger.toggle()
        }
    }
}

#Preview {
    StepCountSaveView()
}
