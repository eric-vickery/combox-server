//
//  BaseDevice.swift
//  Solar Monitor
//
//  Created by Eric Vickery
//

import Foundation
import ObjectMapper
import CocoaMQTT

class BaseDevice: NSObject, Mappable, ObservableObject
{
    static let modbusTimeIntervalSeconds = 2.0
    static let mqttTimeIntervalSeconds = 5.0
    static let mqttClientID = "combox_server"
    static let mqttHost = "192.168.211.1"
    static let mqttPort: UInt16 = 1883
    static let maxSolarPowerAvailable: Float = 10000.0
    static let stateOfChargeThreshold: Float = 90.0
    static let batteryVoltageThreshold: Float = 57.2
    static let evChargerPowerTopic = "dashbox/01001232/c4/watt"
    static let lastPublishedTime = "combox/lastPublishedTime"
    static let availableSolarPowerTopic = "combox/availableSolar"
    static let currentSolarPowerTopic = "combox/currentSolar"
    static let currentLoadTopic = "combox/currentLoad"
    static let batteryVoltageTopic = "combox/batteryVoltage"
    static let batterySOCTopic = "combox/batterySOC"
    static let batteryAmpsTopic = "combox/batteryAmps"
    static let batteryPowerTopic = "combox/batteryPower"
    static let batteryTemperatureFTopic = "combox/batteryTemperature/Fahrenheit"
    static let batteryTemperatureCTopic = "combox/batteryTemperature/Celcius"
    static let chargerStateTopic = "combox/charger/state"

    var evChargerPower: Float = 0.0
    
    @Published var availableSolarPower = ""
    @Published var currentSolarPower = ""
    @Published var loadPower = ""
    @Published var batteryVoltage = ""
    @Published var batterySOC = ""
    @Published var batteryAmps = ""
    @Published var batteryPower = ""
    @Published var batteryTemperatureF = ""
    @Published var batteryTemperatureC = ""
    @Published var chargerState = ""

	var modbus: ModBus?

    var mqtt: CocoaMQTT?

	var registers: [String : ModbusRegister]?
    var connected = false
    var testMode = false
	
	required init?(map: Map)
	{
	}

	func mapping(map: Map)
	{
		registers		<- map["registers"]
	}
	
    class func loadFromFile(deviceName: String, testMode: Bool = false) -> BaseDevice?
	{
		var device: BaseDevice?
		
		if let path = Bundle.main.path(forResource: "DeviceFiles/" + deviceName, ofType: "json")
		{
			do {
				let jsonString = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
		
				switch deviceName
				{
					case "Combox":
						device = Combox(JSONString: jsonString)
						break
					
					case "Outback":
						device = Outback(JSONString: jsonString)
						break
					
					default:
						return nil
				}
			}
			catch let error
			{
				print(error.localizedDescription)
			}
		}
		else
		{
			print("Invalid filename/path.")
		}

        if testMode
        {
            if let device = device
            {
                device.testMode = testMode
                device.currentSolarPower = "1800 W"
                device.loadPower = "650 W"
                device.batteryVoltage = "48.24 V"
                device.batterySOC = "100%"
                device.batteryAmps = "12.00 A"
                device.batteryPower = "400 W"
                device.batteryTemperatureF = "93 F"
                device.batteryTemperatureC = "12 C"
            }
        }
		
		return device
	}

    func initMQTT()
    {
        mqtt = CocoaMQTT(clientID: BaseDevice.mqttClientID, host: BaseDevice.mqttHost, port: BaseDevice.mqttPort)
        if let mqtt = mqtt
        {
            mqtt.allowUntrustCACertificate = true
            mqtt.keepAlive = 60
            mqtt.didReceiveMessage = { mqtt, message, id in
                if message.topic == BaseDevice.evChargerPowerTopic
                {
                    if let floatValue = Float(message.string!)
                    {
                        self.evChargerPower = floatValue
                    }
                }
            }
            mqtt.didChangeState = { mqtt, connectionState in
                if connectionState == .connected
                {
                    mqtt.subscribe(BaseDevice.evChargerPowerTopic, qos: CocoaMQTTQoS.qos1)
                }
            }
            _ = mqtt.connect()
        }
    }
    
    func startGettingData()
    {
        if !testMode
        {
            initMQTT()
            
            // For MQTT
            DispatchQueue.main.async {
                let _ = Timer.scheduledTimer(withTimeInterval: BaseDevice.mqttTimeIntervalSeconds, repeats: true) { timer in
                    self.publishToMQTT()
                }
            }

            // For the UI
            DispatchQueue.main.async {
                let _ = Timer.scheduledTimer(withTimeInterval: BaseDevice.modbusTimeIntervalSeconds, repeats: true) { timer in
                    self.currentSolarPower = String(format: "%.0f", self.getCurrentTotalPowerFromSolar() ?? 0.0)
                    self.availableSolarPower = String(format: "%.0f", self.getAvailableSolarPower())
                    self.loadPower = String(format: "%.0f", self.getCurrentLoadPower() ?? 0.0)
                    self.batteryVoltage = String(format: "%.02f", self.getCurrentBatteryVoltage() ?? 0.0)
                    self.batterySOC = String(format: "%.0f", self.getCurrentBatteryStateOfCharge() ?? 0.0)
                    self.batteryAmps = String(format: "%.02f", self.getCurrentBatteryCurrent() ?? 0.0)
                    self.batteryPower = String(format: "%.0f", self.getCurrentBatteryPower() ?? 0.0)
                    self.batteryTemperatureF = String(format: "%.02f", self.convertToFahrenheit(temperatureInCelsius: self.getCurrentBatteryTemperature() ?? 0.0))
                    self.batteryTemperatureC = String(format: "%.0f", self.getCurrentBatteryTemperature() ?? 0.0)
                    self.chargerState = self.getChargerStatusString()
                }
            }
        }
    }
    
    func publishToMQTT() -> Void
    {
        if self.mqtt!.connState != .connected
        {
            initMQTT()
        }
        
        let today = Date.now
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy hh:mm:ssa"
        self.mqtt!.publish(BaseDevice.lastPublishedTime, withString: formatter.string(from: today), qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.availableSolarPowerTopic, withString: self.availableSolarPower, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.currentSolarPowerTopic, withString: self.currentSolarPower, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.currentLoadTopic, withString: self.loadPower, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.batteryVoltageTopic, withString: self.batteryVoltage, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.batterySOCTopic, withString: self.batterySOC, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.batteryAmpsTopic, withString: self.batteryAmps, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.batteryPowerTopic, withString: self.batteryPower, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.batteryTemperatureFTopic, withString: self.batteryTemperatureF, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.batteryTemperatureCTopic, withString: self.batteryTemperatureC, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.chargerStateTopic, withString: self.chargerState, qos: .qos1, retained: true)
    }
    
    func getAvailableSolarPower() -> Float
    {
        var availableSolarPowerFloat: Float = 0.0
        
        if ((((self.getChargerStatus() ?? Combox.CHARGER_NOT_CHARGING) == Combox.CHARGER_ABSORB) ||
            ((self.getChargerStatus() ?? Combox.CHARGER_NOT_CHARGING) == Combox.CHARGER_FLOAT) ||
            ((self.getChargerStatus() ?? Combox.CHARGER_NOT_CHARGING) == Combox.CHARGER_EQUALIZE)) &&
            (self.getCurrentBatteryPower() ?? 0.0) > 0)

//        if ((self.getCurrentBatteryStateOfCharge() ?? 0.0) > BaseDevice.stateOfChargeThreshold &&
//            (self.getCurrentBatteryVoltage() ?? 0.0) > BaseDevice.batteryVoltageThreshold &&
//            (self.getCurrentBatteryPower() ?? 0.0) > 0)
        {
            availableSolarPowerFloat = BaseDevice.maxSolarPowerAvailable - ((self.getCurrentTotalPowerFromSolar() ?? 0.0) - self.evChargerPower)

        }
        return availableSolarPowerFloat
    }
	
	func connect(address: String?, port: Int32, completionHandler: @escaping (Bool) -> Void)
	{
	}

    func getTypeName() -> String
    {
        return "Undefined"
    }
    
	func getName() -> String?
	{
        return getString("Device Name")
	}
	
	func getFirmwareVersion() -> String?
	{
        return getString("Firmware Version")
	}
	
	func getCurrentBatteryVoltage() -> Float?
	{
		return 0.0
	}
	
	func getCurrentBatteryCurrent() -> Float?
	{
		return 0.0
	}
	
	func getCurrentBatteryPower() -> Float?
	{
		return 0.0
	}
	
	func getCurrentBatteryTemperature() -> Float?
	{
		return 0.0
	}

	func getCurrentBatteryStateOfCharge() -> Float?
	{
		return 0.0
	}

	func getCurrentACOutputVoltage() -> Float?
	{
		return 0.0
	}

	func getCurrentACOutputFrequency() -> Float?
	{
		return 0.0
	}
	
	func getCurrentLoadOutputPower() -> Float?
	{
		return 0.0
	}
	
	func getCurrentLoadPower() -> Float?
	{
		return 0.0
	}
	
	func getCurrentLoadPowerApparent() -> Float?
	{
		return 0.0
	}
	
	func getCurrentPowerFromGenerator() -> Float?
	{
		return 0.0
	}

	func getCurrentGeneratorVoltage() -> Float?
	{
		return 0.0
	}
	
	func getCurrentGeneratorFrequency() -> Float?
	{
		return 0.0
	}

	func getCurrentTotalPowerFromSolar() -> Float?
	{
		return 0.0
	}

	func getCurrentHarvestPowerFromSolar() -> Float?
	{
		return 0.0
	}
	
    func getChargerStatus() -> UInt16?
    {
        return 0
    }
        
    func getChargerStatusString() -> String
    {
        return "Unknown"
    }
        
    func getString(_ registerName: String, offset: UInt16 = 0) -> String?
	{
		if connected, let modbus = self.modbus
		{
			guard let registers = self.registers else {return nil}
			if let register = registers[registerName]
			{
				if register.type == "String"
				{
					return modbus.getString(slaveID: register.deviceId, startingRegister: register.address + offset, numRegistersToRead: register.length / 2)
				}
				else
				{
					return nil
				}
			}
		}
		return nil
	}
	
	func getFloat(_ registerName: String, offset: UInt16 = 0) -> Float?
	{
		if connected, let data = getInt(registerName, offset: offset)
		{
			guard let registers = self.registers else {return nil}
			if let register = registers[registerName]
			{
				return (Float(data) * register.scale) + register.offset
			}
		}
		return nil
	}
	
	func getInt(_ registerName: String, offset: UInt16 = 0) -> Int32?
	{
		if connected, let data = readRegisters(registerName, offset: offset)
		{
			if data.count > 0
			{
				var intValue: Int32 = 0
				
				if data.count == 2
				{
					intValue = Int32(bytesToInt16(msb: data[0], lsb: data[1]))
				}
				else
				{
					intValue = bytesToInt32(byteArray: data)
				}
				return intValue
			}
		}
		return nil
	}
	
	func getUInt32(_ registerName: String, offset: UInt16 = 0) -> UInt32?
	{
		if connected, let data = readRegisters(registerName, offset: offset)
		{
			if data.count > 0
			{
				return bytesToUInt32(byteArray: data)
			}
		}
		return nil
	}
	
	func getUInt16(_ registerName: String, offset: UInt16 = 0) -> UInt16?
	{
		if connected, let data = readRegisters(registerName, offset: offset)
		{
			if data.count > 0
			{
				return bytesToUInt16(msb: data[0], lsb: data[1])
			}
		}
		return nil
	}
	
	func getBoolean(_ registerName: String, offset: UInt16 = 0) -> Bool?
	{
		if connected, let data = readRegisters(registerName, offset: offset)
		{
			if data.count == 2
			{
				return data[1] != 0
			}
		}
		return nil
	}
	
	func readRegisters(_ registerName: String, offset: UInt16 = 0) -> [UInt8]?
	{
		if let modbus = self.modbus
		{
			guard let registers = self.registers else {return nil}
			if let register = registers[registerName]
			{
				return modbus.readRegisters(slaveID: register.deviceId, startingRegister: register.address + offset, numRegistersToRead: register.length)
			}
		}
		return nil
	}
	
	func bytesToUInt16(msb: UInt8, lsb: UInt8) -> UInt16
	{
		return UInt16(UInt16(msb) << 8 | UInt16(lsb))
	}
	
	func bytesToInt16(msb: UInt8, lsb: UInt8) -> Int16
	{
		return Int16(Int16(msb) << 8 | Int16(lsb))
	}
	
	func bytesToUInt32(byteArray: [UInt8]) -> UInt32
	{
		return UInt32(bytesToUInt(byteArray: byteArray))
	}
	
	func bytesToInt32(byteArray: [UInt8]) -> Int32
	{
		return Int32(bitPattern: bytesToUInt(byteArray: byteArray))
	}
	
	func bytesToUInt(byteArray: [UInt8]) -> UInt32
	{
		assert(byteArray.count <= 4)
		
		var result: UInt32 = 0
		
		for idx in 0..<(byteArray.count)
		{
			let shiftAmount = UInt((byteArray.count) - idx - 1) * 8
			result += UInt32(byteArray[idx]) << shiftAmount
		}
		return result
	}
    
    private func convertToFahrenheit(temperatureInCelsius: Float) -> Float
    {
        return temperatureInCelsius * 1.8 + 32
    }
}
