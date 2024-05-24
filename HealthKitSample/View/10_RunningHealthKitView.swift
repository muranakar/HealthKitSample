//
//  10_RunningHealthKitView.swift
//  HealthKitSample
//
//  Created by ryo muranaka on 2024/05/22.
//

import SwiftUI
import HealthKit
import MapKit

struct RunningHealthKitView: View {
    @StateObject private var healthStore = HealthStore()

    var body: some View {
        VStack {
            Text("ランニングデータ")
                .font(.largeTitle)
                .padding()

            Button(action: {
                healthStore.requestAuthorization()
            }) {
                Text("HealthKitへのアクセスを許可")
            }
            .padding()

            if let steps = healthStore.steps {
                Text("歩数: \(steps)")
                    .padding()
            }

            if let heartRate = healthStore.heartRate {
                Text("心拍数: \(heartRate) BPM")
                    .padding()
            }

            MapView(route: healthStore.route)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct MapView: UIViewRepresentable {
    var route: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let polyline = MKPolyline(coordinates: route, count: route.count)
        mapView.addOverlay(polyline)

        if let firstLocation = route.first {
            let region = MKCoordinateRegion(center: firstLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

class HealthStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    let healthStore = HKHealthStore()
    @Published var steps: Int?
    @Published var heartRate: Double?
    @Published var route: [CLLocationCoordinate2D] = []

    private let locationManager = CLLocationManager()
    private var locations: [CLLocation] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAuthorization() {
        let readTypes = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKWorkoutType.workoutType(),
            HKSeriesType.workoutRoute()
        ])

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
            if success {
                self.fetchSteps()
                self.fetchHeartRate()
                self.startTrackingLocation()
            }
        }
    }

    func fetchSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: nil, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            DispatchQueue.main.async {
                self.steps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }

        healthStore.execute(query)
    }

    func fetchHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                return
            }
            DispatchQueue.main.async {
                self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }

        healthStore.execute(query)
    }

    func startTrackingLocation() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
        updateRoute()
    }

    func updateRoute() {
        let coordinates = locations.map { $0.coordinate }
        DispatchQueue.main.async {
            self.route = coordinates
        }
    }
}

struct RunningHealthKitView_Previews: PreviewProvider {
    static var previews: some View {
        RunningHealthKitView()
    }
}

