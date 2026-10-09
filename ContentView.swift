import SwiftUI
import CoreBluetooth
import Combine
import CoreLocation // Pour le GPS
import MapKit       // Pour la carte

class TrackerViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, CLLocationManagerDelegate {
    var centralManager: CBCentralManager!
    var locationManager: CLLocationManager! // Le gestionnaire GPS
    var arduinoPeripheral: CBPeripheral?
    var rssiTimer: Timer?
    
    @Published var isConnected = false
    @Published var signalStrength: Int = -100
    @Published var distanceCategory: String = "Recherche..."
    
    // Variable pour stocker les coordonnées GPS de l'Arduino
    @Published var targetLocation: CLLocationCoordinate2D?
    
    let targetUUID = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Initialisation du GPS
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Demande la permission à l'ouverture
    }
    
    // ---- BLUETOOTH ----
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [targetUUID], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        centralManager.stopScan()
        self.arduinoPeripheral = peripheral
        self.arduinoPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        // MAGIE ICI : Dès que le Bluetooth se connecte, on capture notre position GPS !
        locationManager.requestLocation()
        
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            peripheral.readRSSI()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.distanceCategory = "Perdu"
        }
        rssiTimer?.invalidate()
        centralManager.scanForPeripherals(withServices: [targetUUID], options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        DispatchQueue.main.async {
            self.signalStrength = RSSI.intValue
            if self.signalStrength > -50 {
                self.distanceCategory = "🔥 Brûlant !"
            } else if self.signalStrength > -65 {
                self.distanceCategory = "☀️ Chaud"
            } else if self.signalStrength > -80 {
                self.distanceCategory = "❄️ Froid"
            } else {
                self.distanceCategory = "🧊 Glacial"
            }
        }
    }
    
    // ---- GPS ----
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // On récupère la position la plus récente
        if let location = locations.last {
            DispatchQueue.main.async {
                self.targetLocation = location.coordinate
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erreur GPS : \(error.localizedDescription)")
    }
}

// ---- INTERFACE ----
struct ContentView: View {
    @StateObject var tracker = TrackerViewModel()
    // La caméra qui va zoomer automatiquement sur la carte
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Le radar en haut
            VStack(spacing: 15) {
                Image(systemName: tracker.isConnected ? "airtag.fill" : "airtag")
                    .font(.system(size: 50))
                    .foregroundColor(tracker.isConnected ? .blue : .gray)
                    .symbolEffect(.pulse, options: .repeating, isActive: !tracker.isConnected)
                    .padding(.top, 20)
                
                Text(tracker.isConnected ? "Arduino Connecté" : "Recherche en cours...")
                    .font(.headline)
                
                if tracker.isConnected {
                    Text("\(tracker.distanceCategory) | \(tracker.signalStrength) dBm")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
            
            // La carte en bas
            if let targetLocation = tracker.targetLocation {
                Map(position: $cameraPosition) {
                    // On place un marqueur bleu avec une petite puce dessus
                    Marker("Arduino R4", systemImage: "cpu", coordinate: targetLocation)
                        .tint(.blue)
                }
                .onAppear {
                    // Fait un zoom élégant sur le quartier quand le point apparaît
                    cameraPosition = .region(MKCoordinateRegion(
                        center: targetLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    ))
                }
                .edgesIgnoringSafeArea(.bottom) // Étend la carte jusqu'en bas de l'écran
            } else {
                // Le fond gris en attendant que le signal soit capté
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Text("En attente de localisation...")
                            .foregroundColor(.gray)
                    )
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        .animation(.easeInOut, value: tracker.isConnected)
    }
}
