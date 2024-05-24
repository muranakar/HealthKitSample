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
                NavigationLink(destination:
                                HKSampleQueryDescriptorView()) {
                    Text("HKSampleQueryDescriptor")
                }
                NavigationLink(destination:
                                HKAnchoredObjectQueryDescriptorView()) {
                    Text("HKAnchoredObjectQueryDescriptor")
                }
                NavigationLink(destination:
                                HKStatisticsQueryDescriptorView()) {
                    Text("HKStatisticsQueryDescriptor")
                }
                NavigationLink(destination:
                                HKStatisticsCollectionQueryDescriptorView()) {
                    Text("HKStatisticsCollectionQueryDescriptor")
                }
                NavigationLink(destination:
                                HKCorrelationQueryView()) {
                    Text("HKCorrelationQuery1")
                }
                NavigationLink(destination:
                                CorrelationQueryView()) {
                    Text("HKCorrelationQuery2")
                }
                NavigationLink(destination:
                                HKSourceQueryDescriptorView()) {
                    Text("HKSourceQueryDescriptor")
                }
                NavigationLink(destination:
                                HKActivitySummaryQueryDescriptorView()) {
                    Text("HKActivitySummaryQueryDescriptor")
                }
                NavigationLink(destination:
                                HKDocumentQueryView()) {
                    Text("HKDocumentQuery")
                }
                NavigationLink(destination:
                                HKObserverQueryView()) {
                    Text("HKObserverQuery")
                }
                NavigationLink(destination:
                                RunningHealthKitView()) {
                    Text("RunningHealthKitView")
                }
                NavigationLink(destination:
                                WalkingOneMonthView()) {
                    Text("WalkingOneMonthView")
                }
                NavigationLink(destination:
                                HKStatisticsCollectionQueryDescriptorStepView()) {
                    Text("HKStatisticsCollectionQueryDescriptorStepView")
                }
                NavigationLink(destination:
                                HealthKitSwiftConcurrencyView()
                ) {
                    Text("HealthKitSwiftConcurrencyView")
                }
            }
            .navigationBarTitle("サンプルコード")
        }
    }
}


#Preview {
    ContentView()
}
