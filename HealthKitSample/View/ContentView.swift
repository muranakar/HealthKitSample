//
//  ContentView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/04/30.
//

import SwiftUI
import HealthKit


struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: StepCountSaveView()) {
                    Text("歩数を保存する")
                }
                NavigationLink(destination: StepCountReadView()) {
                    Text("歩数を読み込む")
                }
                NavigationLink(destination:
                    WeeklyStepsView()) {
                    Text("１週間の歩数を取得する")
                }
            }
            .navigationBarTitle("サンプルコード")
        }
    }
}


#Preview {
    ContentView()
}
