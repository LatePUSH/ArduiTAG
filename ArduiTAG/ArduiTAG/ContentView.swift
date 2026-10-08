import SwiftUI
import CoreBluetooth
import Combine

// Le gestionnaire Bluetooth qui s'occupe de la connexion
class TrackerViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var arduinoPeripheral: CBPeripheral?
    var rssiTimer: Timer? // Un minuteur pour mesurer la distance régulièrement
    
    @Published var isConnected = false
    @Published var signalStrength: Int = -100
    @Published var distanceCategory: String = "Recherche..."
    
    // L'UUID défini dans l'Arduino
    let targetUUID = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // 1. On allume le scanner
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [targetUUID], options: nil)
        }
    }
    
    // 2. On a trouvé l'Arduino !
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // On arrête de scanner l'environnement pour économiser la batterie
        centralManager.stopScan()
        
        // On sauvegarde l'Arduino et on s'y connecte !
        self.arduinoPeripheral = peripheral
        self.arduinoPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    // 3. La connexion est réussie
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        // On demande à l'iPhone de mesurer la force du signal (RSSI) toutes les demi-secondes
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            peripheral.readRSSI()
        }
    }
    
    // 4. Si on s'éloigne trop et que ça coupe
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.distanceCategory = "Perdu"
        }
        rssiTimer?.invalidate()
        // On relance le scanner pour essayer de le retrouver
        centralManager.scanForPeripherals(withServices: [targetUUID], options: nil)
    }
    
    // 5. Lecture de la distance (appelé toutes les 0.5 sec)
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        DispatchQueue.main.async {
            self.signalStrength = RSSI.intValue
            
            // Logique de radar "Chaud/Froid"
            if self.signalStrength > -50 {
                self.distanceCategory = "🔥 Brûlant ! (À côté)"
            } else if self.signalStrength > -65 {
                self.distanceCategory = "☀️ Chaud (Même pièce)"
            } else if self.signalStrength > -80 {
                self.distanceCategory = "❄️ Froid (Loin)"
            } else {
                self.distanceCategory = "🧊 Glacial..."
            }
        }
    }
}

// L'interface de l'application
struct ContentView: View {
    @StateObject var tracker = TrackerViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: tracker.isConnected ? "airtag.fill" : "airtag")
                .font(.system(size: 100))
                .foregroundColor(tracker.isConnected ? .blue : .gray)
                .symbolEffect(.pulse, options: .repeating, isActive: !tracker.isConnected)
            
            Text(tracker.isConnected ? "Arduino Connecté" : "Recherche en cours...")
                .font(.title)
                .bold()
            
            if tracker.isConnected {
                VStack(spacing: 20) {
                    Text(tracker.distanceCategory)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.orange)
                    
                    Text("Puissance : \(tracker.signalStrength) dBm")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(30)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.15)))
            }
        }
        .animation(.spring(), value: tracker.isConnected)
    }
}
