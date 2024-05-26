//
//  11_ WalkingOneMonthView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/23.
//

import SwiftUI
import HealthKit
import Charts

fileprivate struct StepData: Identifiable,Sendable {
    let id = UUID()
    let date: Date
    let steps: Int
}

@MainActor
fileprivate class HealthStoreManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var stepData: [StepData] = []
    @State private var myUpdateTask: Task<Void, Never>? = nil

    init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToRead: Set = [stepType]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { (success, error) in
            if success {
                self.fetchStepsData()
            } else {
                print("権限のリクエストに失敗しました: \(String(describing: error))")
            }
        }
    }

    func fetchStepsData() {
        let calendar = Calendar(identifier: .gregorian)
        let todayAM0 = calendar.startOfDay(for: Date())
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: todayAM0),
              let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) else {
            fatalError("*** 開始日または終了日を計算できません ***")
        }

        let thisMonthPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let stepType = HKQuantityType(.stepCount)
        let stepsThisMonthSamplePredicate = HKSamplePredicate.quantitySample(type: stepType, predicate: thisMonthPredicate)
        let everyWeek = DateComponents(day: 7)
      
        let sumOfStepsQuery = HKStatisticsCollectionQueryDescriptor(
            predicate: stepsThisMonthSamplePredicate,
            options: .cumulativeSum,
            anchorDate: endDate,
            intervalComponents: everyWeek)

        Task {
            do {
                let stepCounts = try await sumOfStepsQuery.result(for: healthStore)
                var stepData: [StepData] = []

                stepCounts.statistics().forEach { statistics in
                    if let quantity = statistics.sumQuantity() {
                        let steps = Int(quantity.doubleValue(for: HKUnit.count()))
                        let stepEntry = StepData(date: statistics.startDate, steps: steps)
                    }
                }
                await MainActor.run {
                 // 上記の定数をUIに反映
                }
                
                stepCounts.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let quantity = statistics.sumQuantity() {
                        let steps = Int(quantity.doubleValue(for: HKUnit.count()))
                        let stepEntry = StepData(date: statistics.startDate, steps: steps)
                        stepData.append(stepEntry)
                    }
                }
                await MainActor.run {
                    self.stepData = stepData
                }
            } catch {
                print("歩数データの取得中にエラーが発生しました: \(error)")
            }
        }
    }
}

enum ChartType: String, CaseIterable, Identifiable {
    case line = "Line"
    case bar = "Bar"
    case point = "Point"
    
    var id: String { self.rawValue }
}

struct WalkingOneMonthView: View {
    @StateObject private var healthStore = HealthStoreManager()
    @State private var selectedDate: Date?
    @State private var selectedSteps: Int?
    @State private var selectedChartType: ChartType = .line

    private var chartColor: Color {
        selectedDate != nil ? .cyan : .blue
    }

    var body: some View {
        VStack {
            Text("過去1ヶ月分の歩数")
                .font(.title)
                .padding()

            Picker("グラフの種類", selection: $selectedChartType) {
                ForEach(ChartType.allCases,id: \.self) { chartType in
                    Text(chartType.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if healthStore.stepData.isEmpty {
                Text("データを読み込み中...")
                    .onAppear {
                        healthStore.fetchStepsData()
                    }
            } else {
                Chart {
                    ForEach(healthStore.stepData) { data in
                        switch selectedChartType {
                        case .line:
                            LineMark(
                                x: .value("日付", data.date, unit: .day),
                                y: .value("歩数", data.steps)
                            )
                            .foregroundStyle(chartColor)
                        case .bar:
                            BarMark(
                                x: .value("日付", data.date, unit: .day),
                                y: .value("歩数", data.steps)
                            )
                            .foregroundStyle(chartColor)
                        case .point:
                            PointMark(
                                x: .value("日付", data.date, unit: .day),
                                y: .value("歩数", data.steps)
                            )
                            .foregroundStyle(chartColor)
                        }

                        if let selectedDate {
                            RuleMark(
                                x: .value("日付", selectedDate)
                            )
                            .foregroundStyle(chartColor)
                            .annotation(position: .top) {
                                Text(selectedSteps?.description ?? "???")
                                    .font(.system(size: 13))
                                    .foregroundStyle(chartColor)
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
                .chartYScale(domain: 0...healthStore.stepData.map{ $0.steps }.max()! + 1000)
                .chartXSelection(value: $selectedDate)
                .chartGesture { chart in
                    DragGesture(minimumDistance: 0)
                        .onChanged {
                            chart.selectXValue(at: $0.location.x)
                        }
                        .onEnded { _ in
                            selectedDate = nil
                            selectedSteps = nil
                        }
                }
                .onChange(of: selectedDate) {
                    guard let selectedDate else { return }
                    if let data = healthStore.stepData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                        selectedSteps = data.steps
                    } else {
                        selectedSteps = nil
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct WalkingOneMonthView_Previews: PreviewProvider {
    static var previews: some View {
        WalkingOneMonthView()
    }
}

#Preview {
    WalkingOneMonthView()
}
