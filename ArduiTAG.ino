#include <ArduinoBLE.h>
#include "Arduino_LED_Matrix.h"

ArduinoLEDMatrix matrix;
BLEService beaconService("19B10000-E8F2-537E-4F6C-D104768A1214");

// Dessin du logo Bluetooth (1 = allumé, 0 = éteint)
byte btLogo[8][12] = {
  { 0,0,0, 0,0,1,0,0, 0,0,0,0 },
  { 0,0,0, 0,0,1,1,0, 0,0,0,0 },
  { 0,0,0, 1,0,1,0,1, 0,0,0,0 },
  { 0,0,0, 0,1,1,0,0, 0,0,0,0 },
  { 0,0,0, 1,0,1,0,1, 0,0,0,0 },
  { 0,0,0, 0,0,1,1,0, 0,0,0,0 },
  { 0,0,0, 0,0,1,0,0, 0,0,0,0 },
  { 0,0,0, 0,0,0,0,0, 0,0,0,0 }
};

void setup() {
  Serial.begin(115200);
  matrix.begin(); // Allume l'écran
  
  if (!BLE.begin()) {
    Serial.println("Erreur de démarrage du Bluetooth !");
    while (1);
  }

  BLE.setLocalName("Tracker-Maison");
  BLE.setAdvertisedService(beaconService);
  BLE.advertise();
  
  Serial.println("Balise active ! En attente d'une connexion...");
}

void loop() {
  BLEDevice central = BLE.central(); 

  if (central) {
    // ---> L'IPHONE EST CONNECTÉ <---
    Serial.print("Appareil connecté ! Son adresse MAC est : ");
    Serial.println(central.address()); // Affiche l'adresse de ton iPhone
    
    matrix.renderBitmap(btLogo, 8, 12); // Logo fixe
    
    while (central.connected()) {
      delay(100);
    }
    
    Serial.println("Appareil déconnecté. Reprise de la recherche...");
  } else {
    // ---> EN RECHERCHE <---
    matrix.renderBitmap(btLogo, 8, 12);
    delay(1000);
    matrix.clear();
    delay(1000);
  }
}