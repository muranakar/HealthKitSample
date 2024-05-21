//
//  6_.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/17.
//

import SwiftUI
import HealthKit

// 健康データを管理するためのHealthKitストアのインスタンス
let healthStore = HKHealthStore()

// HKSourceQueryDescriptorを使用してデータを取得するビュー
struct HKSourceQueryDescriptorView: View {
    @State private var sources: [HKSource] = []
    @State private var errorMessage: String?
    @State private var isAuthorized: Bool = false

    var body: some View {
        VStack {
            if isAuthorized {
                List(sources, id: \.bundleIdentifier) { source in
                    VStack(alignment: .leading) {
                        Text(source.name)
                            .font(.headline)
                        Text(source.bundleIdentifier)
                            .font(.subheadline)
                    }
                }
                .onAppear {
                    fetchSources()
                }
            } else {
                Text("HealthKitへのアクセスが許可されていません")
            }
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            requestAuthorization()
        }
    }

    // HealthKitストアからデータ提供元を取得する関数
    func fetchSources() {
        // ディスクリプタを作成
        let sourceDescriptor = HKSourceQueryDescriptor(predicate: .workout())

        Task {
            do {
                // 非同期で結果を取得
                let sources = try await sourceDescriptor.result(for: healthStore)
                // 結果を更新
                self.sources = sources
                
                for source in sources {
                    // ソースをログに出力
                    print("取得したソース: \(source.name), バンドルID: \(source.bundleIdentifier)")
                }
            } catch {
                // エラーメッセージを更新
                self.errorMessage = "データ提供元の取得に失敗しました: \(error.localizedDescription)"
            }
        }
    }

    // HealthKitへのアクセス許可をリクエストする関数
    func requestAuthorization() {
        // 読み取りをリクエストするサンプルタイプ
        let workoutType = HKObjectType.workoutType()

        // 読み取り権限をリクエスト
        healthStore.requestAuthorization(toShare: nil, read: [workoutType]) { success, error in
            DispatchQueue.main.async {
                if success {
                    // アクセス許可が成功した場合
                    self.isAuthorized = true
                } else {
                    // エラーメッセージを更新
                    self.errorMessage = error?.localizedDescription ?? "HealthKitへのアクセスが拒否されました"
                }
            }
        }
    }
}

// プレビュー用のコード
struct HKSourceQueryDescriptorView_Previews: PreviewProvider {
    static var previews: some View {
        HKSourceQueryDescriptorView()
    }
}
