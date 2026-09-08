#if canImport(MAMapKit) && canImport(AMapFoundationKit)
import UIKit
import CoreLocation
import MAMapKit
import AMapFoundationKit

/// Optional provider, compiled only when the host links the official AMap frameworks.
@MainActor public final class DMPAMapProvider: DMPMapProvider {
    private let apiKey: String
    private let hasPrivacyConsent: () -> Bool
    public init(apiKey: String, hasPrivacyConsent: @escaping () -> Bool) {
        self.apiKey = apiKey; self.hasPrivacyConsent = hasPrivacyConsent
    }
    public func create(events: DMPMapEvents) throws -> any DMPMapInstance {
        guard hasPrivacyConsent() else { throw DMPMapError("Map privacy authorization denied") }
        guard !apiKey.isEmpty else { throw DMPMapError("AMap iOS key is required") }
        MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        MAMapView.updatePrivacyAgree(.didAgree)
        AMapServices.shared().apiKey = apiKey
        return DMPAMapInstance(events: events)
    }
}

@MainActor private final class DMPAMapInstance: NSObject, DMPMapInstance, @preconcurrency MAMapViewDelegate, @preconcurrency CLLocationManagerDelegate {
    private let map = MAMapView(frame: .zero)
    private let events: DMPMapEvents
    private var previous: [String: Any] = [:]
    private var markers: [Int: MAPointAnnotation] = [:]
    private var anonymousMarkers: [MAPointAnnotation] = []
    private var destroyed = false
    private var wantsLocation = false
    private let locationManager = CLLocationManager()
    private var pendingMoves: [(Result<[String: Any], Error>) -> Void] = []
    var view: UIView { map }
    init(events: DMPMapEvents) {
        self.events = events
        super.init()
        map.delegate = self
        locationManager.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(pauseLocation), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeLocation), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    func update(_ props: [String: Any]) throws {
        guard !destroyed else { throw DMPMapError("Map destroyed") }
        func changed(_ key: String) -> Bool {
            !NSDictionary(dictionary: ["value": props[key] ?? NSNull()]).isEqual(to: ["value": previous[key] ?? NSNull()])
        }
        if changed("longitude") || changed("latitude") { map.setCenter(try point(props), animated: false) }
        if changed("scale") { map.setZoomLevel((props["scale"] as? NSNumber)?.doubleValue ?? 16, animated: false) }
        map.minZoomLevel = (props["minScale"] as? NSNumber)?.doubleValue ?? 3
        map.maxZoomLevel = (props["maxScale"] as? NSNumber)?.doubleValue ?? 22
        map.isScrollEnabled = props["enableScroll"] as? Bool ?? true
        map.isZoomEnabled = props["enableZoom"] as? Bool ?? true
        map.isRotateEnabled = props["enableRotate"] as? Bool ?? false
        map.isRotateCameraEnabled = props["enableOverlooking"] as? Bool ?? false
        map.showsScale = props["showScale"] as? Bool ?? false
        map.showsCompass = props["showCompass"] as? Bool ?? false
        if changed("rotate") { map.setRotationDegree((props["rotate"] as? NSNumber)?.doubleValue ?? 0, animated: false, duration: 0) }
        if changed("skew") { map.setCameraDegree((props["skew"] as? NSNumber)?.doubleValue ?? 0, animated: false, duration: 0) }
        if changed("markers") { try addMarkers(props["markers"] as? [[String: Any]] ?? [], clear: true) }
        if changed("includePoints"), let points = props["includePoints"] as? [[String: Any]], !points.isEmpty { try fit(points, padding: []) }
        if changed("showLocation") {
            wantsLocation = props["showLocation"] as? Bool ?? false
            if wantsLocation { startLocation() } else { map.showsUserLocation = false }
        }
        previous = props
    }
    private var locationAuthorized: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }
    func invoke(_ command: String, args: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        if command == "moveToLocation", args["longitude"] == nil, args["latitude"] == nil {
            guard !destroyed else { completion(.failure(DMPMapError("Map destroyed"))); return }
            pendingMoves.append(completion)
            startLocation()
            return
        }
        do {
            guard !destroyed else { throw DMPMapError("Map destroyed") }
            var result: [String: Any] = [:]
            switch command {
            case "getCenterLocation": result = coordinate(map.centerCoordinate)
            case "getScale": result = ["scale": map.zoomLevel]
            case "getRegion":
                let rect = map.visibleMapRect
                let southwest = MACoordinateForMapPoint(MAMapPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height))
                let northeast = MACoordinateForMapPoint(MAMapPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y))
                result = ["southwest": coordinate(southwest), "northeast": coordinate(northeast)]
            case "moveToLocation":
                let target: CLLocationCoordinate2D
                if args["longitude"] != nil || args["latitude"] != nil { target = try point(args) }
                else {
                    guard locationAuthorized else { throw DMPMapError("Location permission denied") }
                    guard let location = map.userLocation.location else { throw DMPMapError("Location is not ready; enable show-location first") }
                    target = location.coordinate
                }
                map.setCenter(target, animated: false)
            case "addMarkers":
                guard let values = args["markers"] as? [[String: Any]] else { throw DMPMapError("Markers must be an array") }
                try addMarkers(values, clear: args["clear"] as? Bool ?? false)
            case "removeMarkers":
                guard let ids = args["markerIds"] as? [Int] else { throw DMPMapError("markerIds must be an array") }
                for id in ids { if let marker = markers.removeValue(forKey: id) { map.removeAnnotation(marker) } }
            case "includePoints":
                guard let values = args["points"] as? [[String: Any]] else { throw DMPMapError("Points must be an array") }
                try fit(values, padding: args["padding"] as? [Double] ?? [])
            default: throw DMPMapError("AMap iOS provider does not support \(command)")
            }
            completion(.success(result))
        } catch { completion(.failure(error)) }
    }
    private func addMarkers(_ values: [[String: Any]], clear: Bool) throws {
        var next: [Int: MAPointAnnotation] = [:]
        var anonymous: [MAPointAnnotation] = []
        for value in values {
            let annotation = MAPointAnnotation()
            annotation.coordinate = try point(value)
            annotation.title = value["title"] as? String ?? ""
            annotation.subtitle = (value["callout"] as? [String: Any])?["content"] as? String
            if let rawID = value["id"] {
                guard let number = rawID as? NSNumber, number.doubleValue.isFinite,
                      number.doubleValue >= Double(Int32.min), number.doubleValue <= Double(Int32.max),
                      number.doubleValue == Double(number.intValue), next[number.intValue] == nil else { throw DMPMapError("Marker id must be a unique integer") }
                next[number.intValue] = annotation
            } else {
                anonymous.append(annotation)
            }
        }
        if clear {
            map.removeAnnotations(Array(markers.values) + anonymousMarkers)
            markers.removeAll(); anonymousMarkers.removeAll()
        }
        for (id, annotation) in next {
            if let old = markers.removeValue(forKey: id) { map.removeAnnotation(old) }
            markers[id] = annotation
            map.addAnnotation(annotation)
        }
        anonymousMarkers.append(contentsOf: anonymous)
        map.addAnnotations(anonymous)
    }
    private func fit(_ values: [[String: Any]], padding: [Double]) throws {
        guard !values.isEmpty, padding.isEmpty || padding.count == 4, padding.allSatisfy({ $0.isFinite && $0 >= 0 }) else { throw DMPMapError("Invalid points or padding") }
        let annotations = try values.map { value -> MAPointAnnotation in
            let annotation = MAPointAnnotation(); annotation.coordinate = try point(value); return annotation
        }
        let edges = padding.isEmpty ? [0, 0, 0, 0] : padding
        map.showAnnotations(annotations, edgePadding: UIEdgeInsets(top: edges[0], left: edges[3], bottom: edges[2], right: edges[1]), animated: false)
    }
    @objc private func pauseLocation() { map.showsUserLocation = false }
    @objc private func resumeLocation() {
        if !destroyed && (wantsLocation || !pendingMoves.isEmpty) { startLocation() }
    }
    private func startLocation() {
        guard UIApplication.shared.applicationState != .background else { return }
        if locationAuthorized { map.showsUserLocation = true; return }
        guard locationManager.authorizationStatus == .notDetermined else { failLocation("Location permission denied"); return }
        guard Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil else {
            failLocation("NSLocationWhenInUseUsageDescription is required"); return
        }
        locationManager.requestWhenInUseAuthorization()
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !destroyed, wantsLocation || !pendingMoves.isEmpty else { return }
        if locationAuthorized { map.showsUserLocation = true }
        else if manager.authorizationStatus != .notDetermined { failLocation("Location permission denied") }
    }
    func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
        guard !destroyed, updatingLocation, let userLocation else { return }
        let callbacks = pendingMoves
        pendingMoves.removeAll()
        if !callbacks.isEmpty { map.setCenter(userLocation.coordinate, animated: false) }
        callbacks.forEach { $0(.success([:])) }
        if !wantsLocation { map.showsUserLocation = false }
    }
    private func failLocation(_ message: String) {
        let callbacks = pendingMoves
        pendingMoves.removeAll()
        callbacks.forEach { $0(.failure(DMPMapError(message))) }
        events.error(message)
    }
    func mapInitComplete(_ mapView: MAMapView!) { if !destroyed { events.ready() } }
    func mapView(_ mapView: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) { events.event("tap", self.coordinate(coordinate)) }
    func mapView(_ mapView: MAMapView!, regionWillChangeAnimated animated: Bool, wasUserAction: Bool) { region("begin", wasUserAction) }
    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool, wasUserAction: Bool) { region("end", wasUserAction) }
    private func region(_ type: String, _ userAction: Bool) {
        events.event("regionchange", ["type": type, "causedBy": userAction ? "drag" : "update", "centerLocation": coordinate(map.centerCoordinate), "scale": map.zoomLevel])
    }
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView? {
        guard annotation is MAPointAnnotation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "dimina-map-marker") as? MAPinAnnotationView
            ?? MAPinAnnotationView(annotation: annotation, reuseIdentifier: "dimina-map-marker")!
        view.annotation = annotation
        view.canShowCallout = true
        return view
    }
    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) { markerEvent("markertap", view) }
    func mapView(_ mapView: MAMapView!, didAnnotationViewCalloutTapped view: MAAnnotationView!) { markerEvent("callouttap", view) }
    private func markerEvent(_ type: String, _ view: MAAnnotationView) {
        if let id = markers.first(where: { $0.value === view.annotation })?.key { events.event(type, ["markerId": id]) }
        else if anonymousMarkers.contains(where: { $0 === view.annotation }) { events.event(type, [:]) }
    }
    func mapView(_ mapView: MAMapView!, didFailToLocateUserWithError error: Error!) { failLocation("Location failed") }
    func destroy() {
        guard !destroyed else { return }
        destroyed = true
        pendingMoves.removeAll()
        NotificationCenter.default.removeObserver(self)
        locationManager.delegate = nil
        map.showsUserLocation = false
        map.delegate = nil
        map.removeAnnotations(Array(markers.values) + anonymousMarkers)
        markers.removeAll(); anonymousMarkers.removeAll()
        map.removeFromSuperview()
    }
    private func point(_ value: [String: Any]) throws -> CLLocationCoordinate2D {
        guard let longitude = (value["longitude"] as? NSNumber)?.doubleValue, let latitude = (value["latitude"] as? NSNumber)?.doubleValue,
              longitude.isFinite, latitude.isFinite, (-180...180).contains(longitude), (-90...90).contains(latitude) else { throw DMPMapError("Invalid coordinate") }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    private func coordinate(_ value: CLLocationCoordinate2D) -> [String: Any] { ["longitude": value.longitude, "latitude": value.latitude] }
}
#endif
