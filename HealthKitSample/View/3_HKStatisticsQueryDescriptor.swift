//
//  HKStatisticsQueryDescriptorView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/16.
//

// SwiftUIとHealthKitをインポート
import SwiftUI
import HealthKit
import Charts

// 日々の心拍数の統計情報を表す構造体
struct DailyHeartRateStats: Identifiable {
    let id = UUID()  // ユニークなID
    let date: String  // 日付
    let average: Double  // 平均心拍数
    let min: Double  // 最低心拍数
    let max: Double  // 最高心拍数
    let mostRecent: Double  // 最新の心拍数
}

// メインのビュー
struct HKStatisticsQueryDescriptorView: View {
    @State private var weeklyHeartRateStats: [DailyHeartRateStats] = []  // 週間の心拍数統計情報の配列
    private let healthStore = HKHealthStore()  // HealthKitのストア
    
    var body: some View {
        TabView(selection: $currentPage) {
            VStack {
                Chart {
                    ForEach(weeklyHeartRateStats) { stats in
                        LineMark(
                            x: .value("日付", stats.date),
                            y: .value("最高心拍数", stats.max)
                        )
                        .foregroundStyle(by: .value("max", "最高心拍数"))
                        
                        LineMark(
                            x: .value("日付", stats.date),
                            y: .value("最低心拍数", stats.min)
                        )
                        .foregroundStyle(by: .value("min", "最低心拍数"))
                        
                        LineMark(
                            x: .value("日付", stats.date),
                            y: .value("平均心拍数", stats.average)
                        )
                        .foregroundStyle(by: .value("average", "平均心拍数"))
                        
                        LineMark(
                            x: .value("日付", stats.date),
                            y: .value("最新心拍数", stats.mostRecent)
                        )
                        .foregroundStyle(by: .value("moostRecent", "最新心拍数"))
                    }
                }
                .chartForegroundStyleScale([
                    "最高心拍数": Color.red,
                    "最低心拍数": Color.blue,
                    "平均心拍数": Color.green,
                    "最新心拍数": Color.orange
                ])
                .padding()
                
                Text("過去1週間の心拍数")  // タイトル
            }
            .tag(0)
            .tabItem {
                Label("チャート", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            List(weeklyHeartRateStats) { stats in
                VStack(alignment: .leading) {
                    Text(stats.date)  // 日付
                        .font(.headline)
                    Text("平均: \(String(format: "%.1f", stats.average)) bpm")  // 平均心拍数
                    Text("最小: \(Int(stats.min)) bpm")  // 最低心拍数
                    Text("最大: \(Int(stats.max)) bpm")  // 最高心拍数
                    Text("最新: \(Int(stats.mostRecent)) bpm")  // 最新の心拍数
                }
                .padding(.vertical)
            }
            .tag(1)
            .tabItem {
                Label("リスト", systemImage: "list.bullet")
            }
            
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .interactive))
        
        HStack {
            Button(action: {
                moveToPreviousPage()
            }) {
                Text("前のページ")
            }
            
            Button(action: {
                moveToNextPage()
            }) {
                Text("次のページ")
            }
        }.padding()
            .onAppear {
                requestAuthorization()  // 認可をリクエストする
            }
    }
    @State private var currentPage = 0
    
    private func moveToPreviousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    private func moveToNextPage() {
        if currentPage < 1 {
            currentPage += 1
        }
    }
    
    // 認可をリクエストする関数
    private func requestAuthorization() {
        let heartRateType = HKQuantityType(.heartRate)  // 心拍数のタイプ
        let typesToShare: Set = [heartRateType]
        let typesToRead: Set = [heartRateType]
        
        // 認可をリクエストする
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                Task {
                    do {
                        try await fetchWeeklyHeartRateFixed()  // 週間の心拍数を取得する
                    } catch {
                        print("エラーが発生しました: \(error.localizedDescription)")  // エラーが発生した場合はログを出力
                    }
                }
            } else {
                print("認可に失敗しました")  // 認可失敗時のログ
            }
        }
    }
    
    // 心拍数統計情報を管理するアクター
    actor StatsArrayActor {
        var statsArray: [DailyHeartRateStats] = []  // 心拍数統計情報の配列を初期化
        
        func setStats(dailyHeartRateStats: DailyHeartRateStats) {
            statsArray.append(dailyHeartRateStats)
        }
    }
    
    // 週間の心拍数を取得する関数
    private func fetchWeeklyHeartRate() async throws {
        let calendar = Calendar(identifier: .gregorian)  // グレゴリオ暦を使用
        let endDate = Date()  // 現在の日付を取得
        var startDateComponents = DateComponents()
        startDateComponents.day = -6
        let startDate = calendar.date(byAdding: startDateComponents, to: endDate)!  // 一週間前の日付を計算
        
        var dates: [Date] = []  // 日付の配列を初期化
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: offset, to: startDate) {
                dates.append(date)  // 一週間分の日付を配列に追加
            }
        }
        
        let statsArrayActor = StatsArrayActor()
        
        for date in dates {
            let dayStart = calendar.startOfDay(for: date)  // 日の開始時刻を取得
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!  // 日の終了時刻を取得
            let dayPredicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd)  // 日のサンプルを取得するための条件を作成
            
            let heartRateType = HKQuantityType(.heartRate)  // 心拍数のタイプを指定
            let heartRateDay = HKSamplePredicate.quantitySample(type: heartRateType, predicate: dayPredicate)  // 心拍数のサンプルを取得するための条件を作成
            
            // 心拍数の統計情報を取得するためのクエリを作成
            let averageHeartRateQuery = HKStatisticsQueryDescriptor(predicate: heartRateDay, options: .discreteAverage)
            let minHeartRateQuery = HKStatisticsQueryDescriptor(predicate: heartRateDay, options: .discreteMin)
            let maxHeartRateQuery = HKStatisticsQueryDescriptor(predicate: heartRateDay, options: .discreteMax)
            let mostRecentHeartRateQuery = HKStatisticsQueryDescriptor(predicate: heartRateDay, options: .mostRecent)
            
            // 統計情報を取得し、必要な値を取り出す
            let average = try await averageHeartRateQuery.result(for: healthStore)?
                .averageQuantity()?
                .doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0.0
            
            let min = try await minHeartRateQuery.result(for: healthStore)?
                .minimumQuantity()?
                .doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0.0
            
            let max = try await maxHeartRateQuery.result(for: healthStore)?
                .maximumQuantity()?
                .doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0.0
            
            let mostRecent = try await mostRecentHeartRateQuery.result(for: healthStore)?
                .mostRecentQuantity()?
                .doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0.0
            
            // 日付を適切な形式に変換
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            // 心拍数統計情報を作成し、配列に追加
            let stats = DailyHeartRateStats(
                date: dateFormatter.string(from: dayStart),  // 日付を文字列に変換
                average: average,  // 平均心拍数
                min: min,  // 最低心拍数
                max: max,  // 最高心拍数
                mostRecent: mostRecent  // 最新の心拍数
            )
            await statsArrayActor.setStats(dailyHeartRateStats: stats)
        }
        Task {
            // https://stackoverflow.com/questions/74372835/mutation-of-captured-var-in-concurrently-executing-code を参考に
            self.weeklyHeartRateStats = await statsArrayActor.statsArray  // 週間の心拍数統計情報を更新
        }
    }
    // 週間の心拍数を取得する関数
    private func fetchWeeklyHeartRateFixed() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) else {
            fatalError("開始日時の計算に失敗しました")
        }
        let everyDay = DateComponents(day: 1)
        
        let thisWeek = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let heartRateType = HKQuantityType(.heartRate)
        let heartRatesThisWeek = HKSamplePredicate.quantitySample(type: heartRateType, predicate: thisWeek)
        
        let heartRateQuery = HKStatisticsCollectionQueryDescriptor(
            predicate: heartRatesThisWeek,
            options: [.mostRecent ,.discreteAverage ,.discreteMax ,.discreteMin ,.separateBySource, .cumulativeSum],
            anchorDate: endDate,
            intervalComponents: everyDay
        )
 
        let statsArrayActor = StatsArrayActor()
        var dailyHeartRates: [DailyHeartRateStats] = []
        // 日付を適切な形式に変換
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
                    
        let countPerMinuteUnit = HKUnit.count().unitDivided(by: .minute())

        try await heartRateQuery.result(for: healthStore)
            .statistics().forEach { statistics in
                let average = statistics.averageQuantity()!.doubleValue(for: countPerMinuteUnit)
                let min = statistics.minimumQuantity()!.doubleValue(for: countPerMinuteUnit)
                let max = statistics.maximumQuantity()!.doubleValue(for: countPerMinuteUnit)
                let mostRecent = statistics.mostRecentQuantity()!.doubleValue(for: countPerMinuteUnit)
//                 let sum = statistics.sumQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))

                // 心拍数統計情報を作成し、配列に追加
                let stats = DailyHeartRateStats(
                    date: dateFormatter.string(from: statistics.startDate),  // 日付を文字列に変換
                    average: average,  // 平均心拍数
                    min: min,  // 最低心拍数
                    max: max,  // 最高心拍数
                    mostRecent: mostRecent  // 最新の心拍数
                )
                dailyHeartRates.append(stats)
            }
        for dailyHeartRate in dailyHeartRates {
            await statsArrayActor.setStats(dailyHeartRateStats: dailyHeartRate)
        }
        
        Task {
            // https://stackoverflow.com/questions/74372835/mutation-of-captured-var-in-concurrently-executing-code を参考に
            self.weeklyHeartRateStats = await statsArrayActor.statsArray  // 週間の心拍数統計情報を更新
        }
    }
}

// プレビュー用のコード
struct HKStatisticsQueryDescriptorView_Previews: PreviewProvider {
    static var previews: some View {
        HKStatisticsQueryDescriptorView()
    }
}
