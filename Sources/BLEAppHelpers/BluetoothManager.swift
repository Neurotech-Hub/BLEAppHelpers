//  BluetoothManager.swift
//  Created by Matt Gaidica on 1/23/24.

import CoreBluetooth

public class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var nodeRx: CBCharacteristic?
    var nodeTx: CBCharacteristic?
    public var onNodeTxValueUpdated: ((String) -> Void)?
    
    @Published var nodeTxValue: String = ""
    @Published public var isConnecting: Bool = false
    @Published public var isConnected: Bool = false
    
    let serviceUUID: CBUUID
    let nodeRxUUID: CBUUID
    let nodeTxUUID: CBUUID
    
    public init(serviceUUID: String, nodeRxUUID: String, nodeTxUUID: String) {
        self.serviceUUID = CBUUID(string: serviceUUID)
        self.nodeRxUUID = CBUUID(string: nodeRxUUID)
        self.nodeTxUUID = CBUUID(string: nodeTxUUID)
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func startScanning() {
        isConnecting = true
        
        // Check if Bluetooth is powered on
        if centralManager.state != .poweredOn {
            TerminalManager.shared.addMessage("Bluetooth is not powered on.")
            isConnecting = false
            return
        }
        
        // Begin scanning for devices with the specified service UUID
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        TerminalManager.shared.addMessage("Scanning for peripherals...")
        
        // Include a timeout for the scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { // Adjust the time as needed
            if self.isConnecting {
                TerminalManager.shared.addMessage("Scan timeout. Stopping scan.")
                self.stopScanning()
            }
        }
    }
    
    public func stopScanning() {
        isConnecting = false
        centralManager.stopScan()
    }
    
    public func disconnect() {
        if let connectedPeripheral = self.connectedPeripheral {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        isConnected = false
        isConnecting = false
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        TerminalManager.shared.addMessage("Discovered: \(peripheral.name ?? "unknown")")
        
        // Stop scanning as we found a device
        centralManager.stopScan()
        
        // Save a reference to the peripheral
        connectedPeripheral = peripheral
        connectedPeripheral!.delegate = self
        
        // Connect to the peripheral
        centralManager.connect(connectedPeripheral!)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        TerminalManager.shared.addMessage("Connected to: \(peripheral.name ?? "unknown")")
        
        // Once connected, move to the next step: Discovering services
        peripheral.discoverServices([serviceUUID])
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            TerminalManager.shared.addMessage("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            TerminalManager.shared.addMessage("Discovered service \(service.uuid)")
            if service.uuid == serviceUUID {
                // Discover characteristics for your service
                peripheral.discoverCharacteristics([nodeRxUUID, nodeTxUUID], for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            TerminalManager.shared.addMessage("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case nodeTxUUID:
                TerminalManager.shared.addMessage("Found nodeTx characteristic - notify enabled.")
                nodeTx = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case nodeRxUUID:
                TerminalManager.shared.addMessage("Found nodeRx characteristic.")
                nodeRx = characteristic
            default:
                break
            }
        }
        
        // Update connection status
        DispatchQueue.main.async {
            self.isConnected = true
            self.isConnecting = false
        }
    }
    
    public func writeValue(_ value: String) {
        guard let characteristic = nodeRx else {
            TerminalManager.shared.addMessage("nodeRx characteristic not found.")
            return
        }
        
        if let peripheral = connectedPeripheral, peripheral.state == .connected {
            let data = Data(value.utf8)
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    public func readValue() {
        guard let characteristic = nodeTx else {
            TerminalManager.shared.addMessage("nodeTx characteristic not found.")
            return
        }
        
        if let peripheral = connectedPeripheral, peripheral.state == .connected {
            peripheral.readValue(for: characteristic)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            TerminalManager.shared.addMessage("Error reading characteristic: \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value, let value = String(data: data, encoding: .utf8) {
            let trimmedValue = value.components(separatedBy: "\0").first ?? ""
            DispatchQueue.main.async {
                self.nodeTxValue = trimmedValue
                self.onNodeTxValueUpdated?(trimmedValue)
            }
        }
    }
    
    public func getNodeTxValue() -> String {
        return nodeTxValue
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            TerminalManager.shared.addMessage("Error writing characteristic: \(error.localizedDescription)")
            return
        }
//        TerminalManager.shared.addMessage("Successfully wrote to \(characteristic.uuid)")
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        TerminalManager.shared.addMessage("Disconnected from: \(peripheral.name ?? "unknown")")
        
        // Clear the saved peripheral reference
        connectedPeripheral = nil
        
        // Update connection status
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            TerminalManager.shared.addMessage("Bluetooth is powered on.")
            // Optionally start scanning for devices
            // startScanning()
            
        case .poweredOff:
            TerminalManager.shared.addMessage("Bluetooth is powered off.")
            // Handle Bluetooth being turned off
            
        case .resetting:
            TerminalManager.shared.addMessage("Bluetooth is resetting.")
            // Handle the resetting state
            
        case .unauthorized:
            TerminalManager.shared.addMessage("Bluetooth use is unauthorized.")
            // Handle unauthorized state, perhaps by notifying the user
            
        case .unsupported:
            TerminalManager.shared.addMessage("This device does not support Bluetooth.")
            // Handle the case where Bluetooth isn't supported
            
        case .unknown:
            TerminalManager.shared.addMessage("Bluetooth state is unknown.")
            // Handle unknown state
            
        @unknown default:
            TerminalManager.shared.addMessage("A new state was added that is not handled.")
            // Handle any future states that are not covered above
        }
    }
    
    
}
