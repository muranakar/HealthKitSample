//
//  ContentView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/04/30.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    let healthStore = HKHealthStore()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
    
    func setupHealthKit() {
        if HKHealthStore.isHealthDataAvailable() {
            
        } else {
            
        }
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        healthStore.requestAuthorization(toShare: [distanceType], read: nil) { success, error in
            if success {
                
            } else {
                
            }
        }
    }
}


#Preview {
    ContentView()
}
