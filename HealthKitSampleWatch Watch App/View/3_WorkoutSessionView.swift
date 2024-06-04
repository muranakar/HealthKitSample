//
//  3_WorkoutSessionView.swift
//  HealthKitSampleWatch Watch App
//
//  Created by ryo muranaka on 2024/06/04.
//

import SwiftUI
import HealthKit

// ワークアウトセッションの管理を行うManagerクラス
private class WorkoutSessionManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private var healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    @Published var heartRate: Double = 0.0
    @Published var activeEnergyBurned: Double = 0.0
    @Published var distance: Double = 0.0
    
    override init() {
        super.init()
        self.requestAuthorization()
    }
    
    // HealthKitの認証をリクエストする
    private func requestAuthorization() {
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if success {
                print("認証に成功しました")
            } else {
                print("認証に失敗しました: \(String(describing: error))")
            }
        }
    }
    
    // ワークアウトセッションを開始する
    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            session?.delegate = self
            builder?.delegate = self
            
            session?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { (success, error) in
                if success {
                    print("ワークアウトセッションが開始されました")
                } else {
                    print("ワークアウトセッションの開始に失敗しました: \(String(describing: error))")
                }
            }
        } catch {
            print("ワークアウトセッションの初期化に失敗しました: \(error)")
        }
    }
    
    // ワークアウトセッションを終了する
    func endWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            if success {
                self.builder?.finishWorkout { (workout, error) in
                    if let workout = workout {
                        print("ワークアウトが保存されました: \(workout)")
                        DispatchQueue.main.async {
                            self.resetValues()
                        }
                    } else {
                        print("ワークアウトの保存に失敗しました: \(String(describing: error))")
                    }
                }
            } else {
                print("コレクションの終了に失敗しました: \(String(describing: error))")
            }
        }
    }
    
    // セッションの値をリセットする
    private func resetValues() {
        self.heartRate = 0.0
        self.activeEnergyBurned = 0.0
        self.distance = 0.0
    }
    
    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // セッション状態の変更時に呼ばれる
        print("セッションの状態が変更されました: \(toState)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // セッションのエラー時に呼ばれる
        print("セッションがエラーで終了しました: \(error)")
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    self.heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) ?? 0.0
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    self.activeEnergyBurned = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    self.distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                default:
                    break
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
}

// ワークアウトセッションのビュー
struct WorkoutSessionView: View {
    @ObservedObject private var manager = WorkoutSessionManager()
    
    var body: some View {
        VStack {
            Text("心拍数: \(manager.heartRate, specifier: "%.2f") BPM")
            Text("消費エネルギー: \(manager.activeEnergyBurned, specifier: "%.2f") kcal")
            Text("距離: \(manager.distance, specifier: "%.2f") m")
            HStack {
                Button(action: {
                    manager.startWorkout()
                }) {
                    Text("開始")
                }
                Button(action: {
                    manager.endWorkout()
                }) {
                    Text("終了")
                }
            }
        }
    }
}
