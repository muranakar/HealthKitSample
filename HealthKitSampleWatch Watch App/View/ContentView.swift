//
//  ContentView.swift
//  HealthKitSampleWatch Watch App
//
//  Created by ryo muranaka on 2024/05/15.
//

import SwiftUI
import HealthKit
import HealthKitUI

struct ContentView: View {
    var body: some View {
            NavigationView {
                VStack {
                    NavigationLink(destination: HeartrateView()) {
                        Text("心拍数")
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
                .navigationTitle("Home")
            }
        }
}

#Preview {
    ContentView()
}
