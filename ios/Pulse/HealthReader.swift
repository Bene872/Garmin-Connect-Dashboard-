import Foundation
import HealthKit

final class HealthReader {
    private let store = HKHealthStore()
    private let calendar = Calendar.current
    private let identifiers: [HKQuantityTypeIdentifier] = [.stepCount, .heartRate, .restingHeartRate, .heartRateVariabilitySDNN, .respiratoryRate, .oxygenSaturation]
    private let queue = DispatchQueue(label: "pulse.health.results")
    private func failure(_ message: String) -> NSError { NSError(domain: "PulseHealth", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
    func read(dateString: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(.failure(failure("Apple Health ist auf diesem Gerät nicht verfügbar."))); return }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.calendar = calendar; formatter.dateFormat = "yyyy-MM-dd"
        guard let day = formatter.date(from: dateString), let end = calendar.date(byAdding: .day, value: 1, to: day), day <= Date() else {
            completion(.failure(failure("Ungültiges Datum."))); return
        }
        let quantities = identifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { completion(.failure(failure("Schlafdaten sind nicht verfügbar."))); return }
        let types = Set<HKObjectType>(quantities.map { $0 as HKObjectType } + [sleepType, HKObjectType.workoutType()])
        // Read-only. A successful authorization request does NOT prove read permission.
        store.requestAuthorization(toShare: [], read: types) { success, error in
            if let error = error { completion(.failure(error)); return }
            guard success else { completion(.failure(self.failure("Die Health-Anfrage konnte nicht abgeschlossen werden."))); return }
            self.fetch(day: day, end: end, sleepType: sleepType, completion: completion)
        }
    }
    private func fetch(day: Date, end: Date, sleepType: HKCategoryType, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let group = DispatchGroup()
        var result: [String: Any] = ["source": "apple-health", "date": ISO8601DateFormatter().string(from: day)]
        var errors: [String] = []
        let daily = HKQuery.predicateForSamples(withStart: day, end: end, options: .strictStartDate)
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            group.enter()
            store.execute(HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: daily, options: .cumulativeSum) { _, stats, error in
                self.queue.async { if let quantity = stats?.sumQuantity() { result["steps"] = quantity.doubleValue(for: .count()) } else { result["steps"] = NSNull() }; if let error = error { errors.append(error.localizedDescription) }; group.leave() }
            })
        }
        let metrics: [(HKQuantityTypeIdentifier, String, HKUnit)] = [(.heartRate,"heartRate",HKUnit.count().unitDivided(by: .minute())),(.restingHeartRate,"restingHeartRate",HKUnit.count().unitDivided(by: .minute())),(.heartRateVariabilitySDNN,"hrv",HKUnit.secondUnit(with: .milli)),(.respiratoryRate,"respiratoryRate",HKUnit.count().unitDivided(by: .minute())),(.oxygenSaturation,"oxygenSaturation",.percent())]
        for (identifier, key, unit) in metrics {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            group.enter()
            store.execute(HKSampleQuery(sampleType: type, predicate: daily, limit: key == "heartRate" ? HKObjectQueryNoLimit : 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                self.queue.async {
                    let rows = (samples as? [HKQuantitySample]) ?? []
                    if let sample = rows.first { result[key] = sample.quantity.doubleValue(for: unit) * (key == "oxygenSaturation" ? 100 : 1) } else { result[key] = NSNull() }
                    if key == "heartRate" { result["heartSamples"] = rows.reversed().map { ["time": $0.startDate.timeIntervalSince1970 * 1000, "value": $0.quantity.doubleValue(for: unit)] } }
                    if let error = error { errors.append(error.localizedDescription) }; group.leave()
                }
            })
        }
        let weekStart = calendar.date(byAdding: .day, value: -6, to: day) ?? day
        group.enter()
        store.execute(HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: HKQuery.predicateForSamples(withStart: weekStart, end: end, options: .strictStartDate), limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
            self.queue.async {
                let workouts = (samples as? [HKWorkout]) ?? []
                result["workouts"] = workouts.map { workout -> [String: Any] in
                    let type: String
                    switch workout.workoutActivityType { case .running: type = "Laufen"; case .cycling: type = "Radfahren"; case .hiking: type = "Wandern"; case .walking: type = "Gehen"; case .swimming: type = "Schwimmen"; default: type = "Training" }
                    return ["id":workout.uuid.uuidString,"type":type,"start":workout.startDate.timeIntervalSince1970 * 1000,"durationSeconds":workout.duration,"distanceMeters":workout.totalDistance.map { $0.doubleValue(for: .meter()) as Any } ?? NSNull(),"calories":workout.totalEnergyBurned.map { $0.doubleValue(for: .kilocalorie()) as Any } ?? NSNull()]
                }
                result["trainingMinutes"] = workouts.reduce(0) { $0 + $1.duration / 60 }
                if let error = error { errors.append(error.localizedDescription) }; group.leave()
            }
        })
        // Night ending on selected date. Do not add duplicate intervals from multiple sources.
        let nightStart = calendar.date(byAdding: .hour, value: -6, to: day) ?? day
        let nightEnd = calendar.date(byAdding: .hour, value: 12, to: day) ?? end
        group.enter()
        store.execute(HKSampleQuery(sampleType: sleepType, predicate: HKQuery.predicateForSamples(withStart: nightStart, end: nightEnd, options: []), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            self.queue.async {
                let rows = (samples as? [HKCategorySample]) ?? []
                let sources = Dictionary(grouping: rows.filter { [1,3,4,5].contains($0.value) }, by: { $0.sourceRevision.source.bundleIdentifier })
                // Prefer detailed stages, then most covered time; deterministic tie-breaker.
                let chosen = sources.keys.sorted().max { a,b in
                    func rank(_ key: String) -> Double { (sources[key] ?? []).reduce(0) { sum,row in sum + max(0,min(row.endDate,nightEnd).timeIntervalSince(max(row.startDate,nightStart))) * ([3,4,5].contains(row.value) ? 2 : 1) } }
                    return rank(a) < rank(b)
                }
                let records = chosen.flatMap { sources[$0] } ?? []
                let points = Set(records.flatMap { [max($0.startDate,nightStart), min($0.endDate,nightEnd)] }).sorted()
                var minutes = ["deep":0.0,"core":0.0,"rem":0.0,"unspecified":0.0]
                if points.count > 1 {
                    for i in 0..<(points.count-1) {
                        let start = points[i], finish = points[i+1]
                        guard finish > start else { continue }
                        let overlapping = records.filter { $0.startDate < finish && $0.endDate > start }
                        // Conflicting stages are kept unspecified rather than guessed.
                        let stages = Set(overlapping.map { $0.value }.filter { [3,4,5].contains($0) })
                        if !overlapping.isEmpty { let stage = stages.count == 1 ? stages.first! : 1; let key = stage == 3 ? "core" : stage == 4 ? "deep" : stage == 5 ? "rem" : "unspecified"; minutes[key, default:0] += finish.timeIntervalSince(start)/60 }
                    }
                }
                if records.isEmpty { result["sleep"] = NSNull() } else { result["sleep"] = ["minutes":minutes,"totalMinutes":minutes.values.reduce(0,+),"source":chosen ?? "","score":NSNull()] }
                if let error = error { errors.append(error.localizedDescription) }; group.leave()
            }
        })
        group.notify(queue: queue) { result["errors"] = errors; completion(.success(result)) }
    }
}
