# ArduiTAG

ArduiTAG is a local tracking system prototype inspired by Apple AirTags. It uses an **Arduino UNO R4 WiFi** board as a beacon (BLE Beacon) and an **iOS app (SwiftUI)** for detection and localization.

## Features

- **BLE (Bluetooth Low Energy) Broadcasting** via a custom Service UUID.
- **Visual Feedback (LED Matrix)**: An animated Bluetooth logo on the board blinks while searching and remains solid upon connection.
- **Proximity Radar (RSSI)**: Real-time "Hot/Cold" interface on the iPhone to estimate distance.
- **GPS Localization (MapKit)**: Automatically places a pin on an Apple Map at the exact moment the beacon is detected.

## Hardware Requirements

* An **Arduino UNO R4 WiFi** board
* An **iPhone** (physical device required, as the Xcode simulator does not support Bluetooth)
* A Mac with **Xcode**
* *(Optional)* A power bank / external battery to make the Arduino portable

## Project Structure

* **`/Arduino`**: Contains the C++ code (`.ino`) to upload to the board. *(Requires installing the `ArduinoBLE` library)*.
* **`/iOS`**: Contains the complete Xcode project. Built with Swift (SwiftUI), `CoreBluetooth`, `CoreLocation`, and `MapKit`.

## Installation & Usage

### 1. Arduino Side
1. Open the file located in the `/Arduino` folder using the Arduino IDE.
2. Install the `ArduinoBLE` library via the Library Manager.
3. Upload the code to your UNO R4 WiFi.

### 2. iPhone Side
1. Open the Xcode project located in the `/iOS` folder.
2. Connect your iPhone to your Mac via USB.
3. At the top of Xcode, select your physical iPhone as the target (instead of the simulator).
4. Run the application (Play button).

> **Note:** The app will ask for *Bluetooth* and *Location* permissions on the first launch. These are mandatory to detect the board and drop the pin on the map!
