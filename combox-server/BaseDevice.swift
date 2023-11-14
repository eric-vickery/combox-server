//
//  BaseDevice.swift
//  Solar Monitor
//
//  Created by Eric Vickery
//

import Foundation
import OSLog
import ObjectMapper
import CocoaMQTT
import Alamofire

class BaseDevice: NSObject, Mappable, ObservableObject
{
    static let dashboxTimeIntervalSeconds = 2.0
    static let dashboxHost = "dashbox.vickeryranch.com"
    static let modbusTimeIntervalSeconds = 2.0
    static let mqttTimeIntervalSeconds = 5.0
    static let mqttClientID = "combox_server"
    static let mqttHost = "192.168.211.1"
    static let mqttPort: UInt16 = 1883
    
    static let maxSolarPowerAvailable: Float = 9600.0
    static let maxPowerAvailableToEVCharger: Float = 7200.0
    static let stateOfChargeThreshold: Float = 90.0
    static let batteryVoltageHigherThreshold: Float = 57.2
    static let batteryVoltageLowerThreshold: Float = 52.5
    static let dischargeDelayIntervalSeconds = 5*60.0
    static let dischargeBackoffIntervalSeconds = 30*60.0
    static let maxNumBackoffs = 3
    static let minHouseBatteryStateOfChargeForEVCharging = 97.5
//    static let evChargerPowerTopic = "dashbox/01001232/c4/watt"
    static let lastPublishedTimeTopic = "combox/lastPublishedTime"
    
    // Combox topics
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
    static let inHouseBatteryDischargingDelayTopic = "combox/operation/inHouseBatteryDischargingDelay"
    static let inDischargeBackoffTopic = "combox/operation/inDischargeBackoff"
    static let numBackoffsTopic = "combox/operation/numBackoffs"
    static let houseBatteryHitFullChargeTopic = "combox/operation/houseBatteryHitFullCharge"
    static let reasonForLowOrNoSolarAvailableTopic = "combox/operation/reasonForLowOrNoSolarAvailable"
    
    // Dashbox topics
    static let mainTopic = "dashbox/vickeryranch/main"
    static let wellPumpTopic = "dashbox/vickeryranch/wellPump"
    static let evChargerTopic = "dashbox/vickeryranch/evCharger"
    static let southWallPlugTopic = "dashbox/vickeryranch/southWallPlug"
    static let airCompressorTopic = "dashbox/vickeryranch/airCompressor"
    static let southWest240Topic = "dashbox/vickeryranch/southWest240"
    static let welderTopic = "dashbox/vickeryranch/welder"
    static let dustCollectorTopic = "dashbox/vickeryranch/dustCollector"
    static let wetWallTopic = "dashbox/vickeryranch/wetWall"
    static let southWest120Topic = "dashbox/vickeryranch/southWest120"
    static let solarRoomTempFTopic = "dashbox/vickeryranch/solarRoomTempF"
    static let solarRoomTempCTopic = "dashbox/vickeryranch/solarRoomTempC"
    static let entryTopic = "dashbox/vickeryranch/entry"
    static let diningRoomHeaterTopic = "dashbox/vickeryranch/diningRoomHeater"
    static let hallLightsPlugsTopic = "dashbox/vickeryranch/hallLightsPlugs"
    static let kitchenDiningLightsTopic = "dashbox/vickeryranch/kitchenDiningLights"
    static let kitchenWestWallPlugsTopic = "dashbox/vickeryranch/kitchenWestWallPlugs"
    static let kitchenSouthWallPlugsTopic = "dashbox/vickeryranch/kitchenSouthWallPlugs"
    static let washingMachineTopic = "dashbox/vickeryranch/washingMachine"
    static let dryerTopic = "dashbox/vickeryranch/dryer"
    static let masterBathPelletTopic = "dashbox/vickeryranch/masterBathPellet"
    static let masterBedroomTopic = "dashbox/vickeryranch/masterBedroom"
    static let kateOfficeTopic = "dashbox/vickeryranch/kateOffice"
    static let ericOfficeTopic = "dashbox/vickeryranch/ericOffice"
    static let livingroomPelletTVTopic = "dashbox/vickeryranch/livingroomPelletTV"
    static let stoveDishwasherTopic = "dashbox/vickeryranch/stoveDishwasher"
    static let refrigeratorTopic = "dashbox/vickeryranch/refrigerator"
    static let livingroomLightTopic = "dashbox/vickeryranch/livingroomLight"
    static let utilityRoomPlugsTopic = "dashbox/vickeryranch/utilityRoomPlugs"
    static let utilityRoomTempFTopic = "dashbox/vickeryranch/utilityRoomTempF"
    static let utilityRoomTempCTopic = "dashbox/vickeryranch/utilityRoomTempC"
    static let houseVoltageTopic = "dashbox/vickeryranch/houseVoltage"

    let logger = Logger(subsystem: "com.vickeryranch.combox_server", category: "all")
    var evChargerPower: Float = 0.0
    var availableSolarPowerFloat: Float = 0.0
    @Published var inHouseBatteryDischargingDelay = false
    @Published var inDischargeBackoff = false
    @Published var numBackoffs = 0
    @Published var houseBatteryHitFullCharge = false
    @Published var reasonForLowOrNoSolarAvailable = ""
    @Published var lastPublishedTime = ""
    
    // Combox values
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
    
    // Dashbox values
    @Published var main = ""
    @Published var wellPump = ""
    @Published var evCharger = ""
    @Published var southWallPlug = ""
    @Published var airCompressor = ""
    @Published var southWest240 = ""
    @Published var welder = ""
    @Published var dustCollector = ""
    @Published var wetWall = ""
    @Published var southWest120 = ""
    @Published var solarRoomTempF = ""
    @Published var solarRoomTempC = ""
    @Published var entry = ""
    @Published var diningRoomHeater = ""
    @Published var hallLightsPlugs = ""
    @Published var kitchenDiningLights = ""
    @Published var kitchenWestWallPlugs = ""
    @Published var kitchenSouthWallPlugs = ""
    @Published var washingMachine = ""
    @Published var dryer = ""
    @Published var masterBathPellet = ""
    @Published var masterBedroom = ""
    @Published var kateOffice = ""
    @Published var ericOffice = ""
    @Published var livingroomPelletTV = ""
    @Published var stoveDishwasher = ""
    @Published var refrigerator = ""
    @Published var livingroomLight = ""
    @Published var utilityRoomPlugs = ""
    @Published var utilityRoomTempF = ""
    @Published var utilityRoomTempC = ""
    @Published var houseVoltage = ""


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
            _ = mqtt.connect()
        }
        logger.log("MQTT Initialized")
    }
    
    func startGettingData()
    {
        if !testMode
        {
            
            // Setup a cleanup "task" that runs once a day
            NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { _ in
                self.evChargerPower = 0.0
                self.availableSolarPowerFloat = 0.0
                self.inHouseBatteryDischargingDelay = false
                self.inDischargeBackoff = false
                self.numBackoffs = 0
                self.houseBatteryHitFullCharge = false
                self.logger.log("Cleaned up")
                self.reasonForLowOrNoSolarAvailable = "Overnight reset"
            }
            
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
                    self.availableSolarPowerFloat = self.getAvailableSolarPower()
                    self.availableSolarPower = String(format: "%.0f", self.availableSolarPowerFloat)
                    self.loadPower = String(format: "%.0f", self.getCurrentLoadPower() ?? 0.0)
                    self.batteryVoltage = String(format: "%.02f", self.getCurrentBatteryVoltage() ?? 0.0)
                    self.batterySOC = String(format: "%.0f", self.getCurrentBatteryStateOfCharge() ?? 0.0)
                    self.batteryAmps = String(format: "%.02f", self.getCurrentBatteryCurrent() ?? 0.0)
                    self.batteryPower = String(format: "%.0f", self.getCurrentBatteryPower() ?? 0.0)
                    self.batteryTemperatureF = String(format: "%.02f", self.convertToFahrenheit(temperatureInCelsius: self.getCurrentBatteryTemperature() ?? 0.0))
                    self.batteryTemperatureC = String(format: "%.0f", self.getCurrentBatteryTemperature() ?? 0.0)
                    self.chargerState = self.getChargerStatusString()
                    
                    // See if we have gotten to 100% charged
                    if self.getCurrentBatteryStateOfCharge() == 100.0
                    {
                        // Only log this the first time we get here
                        if !self.houseBatteryHitFullCharge
                        {
                            self.logger.log("Hit full charge")
                        }
                        self.houseBatteryHitFullCharge = true
                    }
                }
                
                let _ = Timer.scheduledTimer(withTimeInterval: BaseDevice.dashboxTimeIntervalSeconds, repeats: true) { timer in
                    let URL = "http://\(BaseDevice.dashboxHost)/index.php/pages/search/getWattVals"
                    AF.request(URL).responseJSON { (response) in
                        if response.error != nil
                        {
                            self.logger.error("Couldn't connect to the dashbox")
                            return
                        }

                        if let deviceList = response.value as? [String:[String:[Any]]]
                        {
                            if let wattValues = deviceList["95"]!["watts"]
                            {
                                self.main = String(wattValues[0] as! Double)
                                self.wellPump = String(wattValues[1] as! Double)
                                self.evCharger = String(wattValues[3] as! Double)
                                self.evChargerPower = Float(wattValues[3] as! Double)
                                self.southWallPlug = String(wattValues[5] as! Double)
                                self.airCompressor = String(wattValues[6] as! Double)
                                self.southWest240 = String(wattValues[7] as! Double)
                                self.welder = String(wattValues[8] as! Double)
                                self.dustCollector = String(wattValues[9] as! Double)
                                self.wetWall = String(wattValues[10] as! Double)
                                self.southWest120 = String(wattValues[11] as! Double)
                                self.solarRoomTempF = String(format: "%.02f", wattValues[12] as! Double)
                                self.solarRoomTempC = String(format: "%.02f", self.convertToCelcuis(temperatureInFahrenheit: Float(wattValues[12] as! Double)))
                            }
                            
                            if let wattValues = deviceList["96"]!["watts"]
                            {
                                self.entry = String(wattValues[1] as! Double)
                                self.diningRoomHeater = String(wattValues[2] as! Double)
                                self.hallLightsPlugs = String(wattValues[3] as! Double)
                                self.kitchenDiningLights = String(wattValues[4] as! Double)
                                self.kitchenWestWallPlugs = String(wattValues[6] as! Double)
                                self.kitchenSouthWallPlugs = String(wattValues[7] as! Double)
                                self.washingMachine = String(wattValues[8] as! Double)
                                self.dryer = String(wattValues[9] as! Double)
                                self.masterBathPellet = String(wattValues[10] as! Double)
                                self.masterBedroom = String(wattValues[11] as! Double)
                                self.kateOffice = String(wattValues[12] as! Double)
                                self.ericOffice = String(wattValues[13] as! Double)
                                self.livingroomPelletTV = String(wattValues[14] as! Double)
                                self.stoveDishwasher = String(wattValues[15] as! Double)
                                self.refrigerator = String(wattValues[16] as! Double)
                                self.livingroomLight = String(wattValues[17] as! Double)
                                self.utilityRoomPlugs = String(wattValues[18] as! Double)
                                self.utilityRoomTempF = String(format: "%.02f", wattValues[20] as! Double)
                                self.utilityRoomTempC = String(format: "%.02f", self.convertToCelcuis(temperatureInFahrenheit: Float(wattValues[20] as! Double)))
                                self.houseVoltage = String(wattValues[20] as! Double)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func publishToMQTT() -> Void
    {
        if self.mqtt!.connState != .connected
        {
            initMQTT()
            self.logger.log("Reinitialized MQTT")
        }
        
        let today = Date.now
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy hh:mm:ssa"
        self.lastPublishedTime = formatter.string(from: today)
        // Combox topics
        self.mqtt!.publish(BaseDevice.lastPublishedTimeTopic, withString: self.lastPublishedTime, qos: .qos1, retained: true)
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
        self.mqtt!.publish(BaseDevice.inHouseBatteryDischargingDelayTopic, withString: self.inHouseBatteryDischargingDelay ? "true" : "false", qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.inDischargeBackoffTopic, withString: self.inDischargeBackoff ? "true" : "false", qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.numBackoffsTopic, withString: String(format: "%0d", self.numBackoffs), qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.houseBatteryHitFullChargeTopic, withString: self.houseBatteryHitFullCharge ? "true" : "false", qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.reasonForLowOrNoSolarAvailableTopic, withString: self.chargerState, qos: .qos1, retained: true)

        // Dashbox topics
        self.mqtt!.publish(BaseDevice.mainTopic, withString: self.main, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.wellPumpTopic, withString: self.wellPump, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.evChargerTopic, withString: self.evCharger, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.southWallPlugTopic, withString: self.southWallPlug, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.airCompressorTopic, withString: self.airCompressor, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.southWest240Topic, withString: self.southWest240, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.welderTopic, withString: self.welder, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.dustCollectorTopic, withString: self.dustCollector, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.wetWallTopic, withString: self.wetWall, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.southWest120Topic, withString: self.southWest120, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.solarRoomTempFTopic, withString: self.solarRoomTempF, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.solarRoomTempCTopic, withString: self.solarRoomTempC, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.entryTopic, withString: self.entry, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.diningRoomHeaterTopic, withString: self.diningRoomHeater, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.hallLightsPlugsTopic, withString: self.hallLightsPlugs, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.kitchenDiningLightsTopic, withString: self.kitchenDiningLights, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.kitchenWestWallPlugsTopic, withString: self.kitchenWestWallPlugs, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.kitchenSouthWallPlugsTopic, withString: self.kitchenSouthWallPlugs, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.washingMachineTopic, withString: self.washingMachine, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.dryerTopic, withString: self.dryer, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.masterBathPelletTopic, withString: self.masterBathPellet, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.masterBedroomTopic, withString: self.masterBedroom, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.kateOfficeTopic, withString: self.kateOffice, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.ericOfficeTopic, withString: self.ericOffice, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.livingroomPelletTVTopic, withString: self.livingroomPelletTV, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.stoveDishwasherTopic, withString: self.stoveDishwasher, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.refrigeratorTopic, withString: self.refrigerator, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.livingroomLightTopic, withString: self.livingroomLight, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.utilityRoomPlugsTopic, withString: self.utilityRoomPlugs, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.utilityRoomTempFTopic, withString: self.utilityRoomTempF, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.utilityRoomTempCTopic, withString: self.utilityRoomTempC, qos: .qos1, retained: true)
        self.mqtt!.publish(BaseDevice.houseVoltageTopic, withString: self.houseVoltage, qos: .qos1, retained: true)
    }
    
    func getAvailableSolarPower() -> Float
    {
        self.checkHouseBatteryStateOfCharge()
        
        // During a discharge backoff return that we have no solar power
        if self.inDischargeBackoff
        {
            return 0.0
        }
        
        if (!self.houseChargerInStateForEVCharging() ||
            !((self.getCurrentBatteryVoltage() ?? 0.0) >= self.getBatteryVoltageThresholdForEVCharging()))
        {
            return 0.0
        }
        
        // We may be in a delay because of drawing from the house battery
        if self.inHouseBatteryDischargingDelay
        {
            return self.availableSolarPowerFloat
        }
        
        // We are in a charging state and have a high enough voltage
        if ((self.getCurrentBatteryPower() ?? 0.0) < 0)
        {
            // Start a timer and if we are still in discharge more after the timer then return no solar available
            self.setHouseBatteryDischargeDelay()
            
            // Return the value we previously calculated
            return self.availableSolarPowerFloat
        }
        
        // We have power into the house battery
        return min(BaseDevice.maxSolarPowerAvailable - ((self.getCurrentTotalPowerFromSolar() ?? 0.0) - self.evChargerPower), BaseDevice.maxPowerAvailableToEVCharger)
    }
    
    func checkHouseBatteryStateOfCharge() -> Void
    {
        // So if we got fully charged and then started down then turn off EV charging. This usually happens at the end of the day or if it is very cloudy
        if self.houseBatteryHitFullCharge
        {
            if let stateOfCharge = self.getCurrentBatteryStateOfCharge()
            {
                
                if stateOfCharge < Float(BaseDevice.minHouseBatteryStateOfChargeForEVCharging)
                {
                    if !self.inDischargeBackoff
                    {
                        self.logger.log("In permanent discharge backoff due to pulling the battery down")
                    }
                    self.inDischargeBackoff = true
                }
            }
        }
        
    }

    func setHouseBatteryDischargeDelay() -> Void
    {
        self.reasonForLowOrNoSolarAvailable = "House battery is discharging"
        self.logger.log("In discharge delay")
        self.inHouseBatteryDischargingDelay = true
        let _ = Timer.scheduledTimer(withTimeInterval: BaseDevice.dischargeDelayIntervalSeconds, repeats: true) { timer in
            // If we are still negative then go into backoff
            if ((self.getCurrentBatteryPower() ?? 0.0) < 0)
            {
                self.setDischargeBackoff()
                self.inDischargeBackoff = true
            }
            self.inHouseBatteryDischargingDelay = false
        }
    }
    
    // This function is used to set a backoff timer and possibly stay in backoff if the number of times in backoff has been exceeded or the battery is still discharging
    func setDischargeBackoff() -> Void
    {
        self.reasonForLowOrNoSolarAvailable = "House battery is still discharging"
        self.logger.log("In discharge backoff")
        self.inDischargeBackoff = true
        if self.numBackoffs < BaseDevice.maxNumBackoffs
        {
            let _ = Timer.scheduledTimer(withTimeInterval: BaseDevice.dischargeBackoffIntervalSeconds, repeats: true) { timer in
                self.numBackoffs += 1
                if self.numBackoffs >= BaseDevice.maxNumBackoffs
                {
                    return
                }
                // If we are still negative then stay in backoff for another timer interval or stay in backoff if we have exceeded the number of backoffs
                if ((self.getCurrentBatteryPower() ?? 0.0) < 0)
                {
                    self.setDischargeBackoff()
                }
                self.inDischargeBackoff = false
            }
        }
    }
    
    func houseChargerInStateForEVCharging() -> Bool
    {
        let chargerStatus = (self.getChargerStatus() ?? Combox.CHARGER_NOT_CHARGING)
        
        return (chargerStatus == Combox.CHARGER_BULK ||
                chargerStatus == Combox.CHARGER_ABSORB ||
                chargerStatus == Combox.CHARGER_FLOAT ||
                chargerStatus == Combox.CHARGER_EQUALIZE)
    }
    
    func getBatteryVoltageThresholdForEVCharging() -> Float
    {
        let chargerStatus = (self.getChargerStatus() ?? Combox.CHARGER_NOT_CHARGING)
        
        // If the EV charger is not on and we are not in float mode or not charging mode
        if self.evChargerPower < 500.0
        {
            if chargerStatus == Combox.CHARGER_FLOAT || chargerStatus == Combox.CHARGER_NOT_CHARGING
            {
                return BaseDevice.batteryVoltageLowerThreshold
            }
            else
            {
                return BaseDevice.batteryVoltageHigherThreshold
            }
        }
        else
        {
            return BaseDevice.batteryVoltageLowerThreshold
        }
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
    
    private func convertToCelcuis(temperatureInFahrenheit: Float) -> Float
    {
        return ((temperatureInFahrenheit - 32) * 5) / 9
    }
}

//struct BrultechResponse: Decodable
//{
//    let 95: GEM
//    let 96: GEM
//}
//
//struct GEM: Decodable
//{
//    let thresh: [Int]
//    let watts: [Int]
//}
