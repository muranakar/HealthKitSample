//
//  8_.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/18.
//

import SwiftUI
import HealthKit

struct HKDocumentQueryView: View {
    @State private var documents: [HKDocumentSample] = []
    @State private var isLoading: Bool = true

    private let healthStore = HKHealthStore()
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("ドキュメントを読み込み中...")
                } else if documents.isEmpty {
                    Text("ドキュメントが見つかりません")
                } else {
                    List(documents, id: \.uuid) { document in
                        Text("ドキュメント: \(document.uuid)")
                    }
                }
            }
            .navigationTitle("ヘルスドキュメント")
            .onAppear(perform: loadDocuments)
        }
    }
    
    private func loadDocuments() {
        guard let cdaType = HKObjectType.documentType(forIdentifier: .CDA) else {
            fatalError("CDAドキュメントタイプを作成できません。")
        }
        var allDocuments = [HKDocumentSample]()
        
        let cdaQuery = HKDocumentQuery(documentType: cdaType,
                                       predicate: nil,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil,
                                       includeDocumentData: false) { (query, resultsOrNil, done, errorOrNil) in
            if let error = errorOrNil {
                print("ドキュメントの取得エラー: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let results = resultsOrNil else {
                self.isLoading = false
                return
            }
            
            allDocuments += results
            
            if done {
                DispatchQueue.main.async {
                    self.documents = allDocuments
                    self.isLoading = false
                }
            }
        }
        
        healthStore.execute(cdaQuery)
    }
}
