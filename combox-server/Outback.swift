//
//  Outback.swift
//  Solar Monitor
//
//  Created by Eric Vickery
//

import Foundation

class Outback: BaseDevice
{
	static let MODBUS_PORT: Int32 = 502
	
	static let MB_MAX_REGISTERS = 125
	static let SUNSPEC_MODBUS_REGISTER_OFFSET: UInt16 = 40001

	static let SUNSPEC_MODBUS_MAP_ID: UInt32 = 0x53756e53
	static let SUNSPEC_MODBUS_MAP_ID_MSW = SUNSPEC_MODBUS_MAP_ID >> 16
	static let SUNSPEC_MODBUS_MAP_ID_LSW = SUNSPEC_MODBUS_MAP_ID & 0x0000FFFF

	static let SUNSPEC_COMMON_MODEL_BLOCK_DID: UInt16 =  0x0001
	static let SUNSPEC_AGGREGATOR_BLOCK_DID: UInt16 =  0x0002
	static let SUNSPEC_END_BLOCK_DID: UInt16 =  0xffff
	static let SUNSPEC_INVERTER_SINGLE_DID: UInt16 =  101
	static let SUNSPEC_INVERTER_SPLIT_DID: UInt16 =  102
	static let SUNSPEC_INVERTER_3PHASE_DID: UInt16 =  103
	static let SUNSPEC_BASIC_CC_DID: UInt16 =  64111
	static let SUNSPEC_OUTBACK_DID: UInt16 =  64110
	static let SUNSPEC_OUTBACK_FM_CC_DID: UInt16 =  64112
	static let SUNSPEC_OUTBACK_FX_DID: UInt16 =  64113
	static let SUNSPEC_OUTBACK_FX_CONFIG_DID: UInt16 =  64114
	static let SUNSPEC_OUTBACK_GS_SPLIT_DID: UInt16 =  64115
	static let SUNSPEC_OUTBACK_GS_CONFIG_DID: UInt16 =  64116
	static let SUNSPEC_OUTBACK_GS_SINGLE_DID: UInt16 =  64117
	static let SUNSPEC_OUTBACK_FNDC_DID: UInt16 =  64118
	static let SUNSPEC_OUTBACK_FNDC_CONFIG_DID: UInt16 =  64119
	static let SUNSPEC_OUTBACK_SYS_CONTROL_DID: UInt16 =  64120
	static let SUNSPEC_OUTBACK_STATISTICS_DID: UInt16 =  64255
	
	static let MAX_DEVICES = 28

	static let I_AC_POWER_FIELD_ADDRESS: UInt16 = 14
	
	static let FX_LOAD_kW_FIELD_ADDRESS: UInt16 = 36
	
	static let CC_CHARGER_STATE_ADDRESS: UInt16 = 12
	
	static let CCCONFIG_LOG_DAILY_ABSORB_TIME_ADDRESS: UInt16 = 60
	
	static let BATTERY_100_PERCENT_CHARGED_VOLTAGE: Float = 25.46
	static let BATTERY_20_PERCENT_CHARGED_VOLTAGE: Float = 23.46
	static let BATTERY_SOC_VOLTAGE_DELTA: Float = 2.0
	
	let chargerStates = ["Silent","Float","Bulk","Absorb","EQ"]
	
	static let ADDR_START = SUNSPEC_MODBUS_REGISTER_OFFSET - 1

	// Device Addresses
	var deviceOffsetTable = [UInt16](repeating: 0, count: MAX_DEVICES + 1)
	var deviceTable = [UInt16](repeating: 0, count: MAX_DEVICES + 1)
	var inverters = [UInt16]()
	var chargeControllers = [UInt16]()
	var chargeControllersConfig = [UInt16]()
	var gatewayAddress: UInt16 = 0
	
	// Config Info
	var firmwareVersion = ""
	var dhcpEnabled = true
	var ipAddress = ""
	var gatewayIPAddress = ""
	var dns1IPAddress = ""
	var dns2IPAddress = ""
	var errors: UInt16 = 0

	var numDevices: Int = 0

	override func connect(address: String?, port: Int32, completionHandler: @escaping (Bool) -> Void)
	{
		var addr: UInt16 = 0
		var numRegistersToRead = 0
		var offset: UInt16 = 0
		var data = [UInt8]()
		
		if (self.modbus == nil)
		{
			self.modbus = ModBus()
		}
		
		if let modbus = self.modbus, let address = address
		{
			if modbus.connect(address: address, port: Outback.MODBUS_PORT)
			{
                connected = true
				if Outback.SUNSPEC_MODBUS_MAP_ID != getSunSpecID()
				{
					print("Not SunSpec")
					numDevices = 0
                    connected = false
					completionHandler(false)
					return
				}
			}
			else
			{
				print("Outback could not connect")
				numDevices = 0
                connected = false
				completionHandler(false)
				return
			}
			
			//Get Device Table
			addr = Outback.ADDR_START
			numRegistersToRead = 2

			repeat
			{
				if numDevices >= Outback.MAX_DEVICES
				{
					break
				}

				addr += offset + 2
				deviceOffsetTable[numDevices] = addr

				data = modbus.readRegisters(slaveID: 0xFF, startingRegister: addr, numRegistersToRead: numRegistersToRead)

				// Strange calculation because we get back 2 bytes for each register
				if data.count != numRegistersToRead * 2
				{
                    connected = false
					completionHandler(false)
					return
				}
				else
				{
					offset = bytesToUInt16(msb: data[2], lsb: data[3])
					deviceTable[numDevices] =  bytesToUInt16(msb: data[0], lsb: data[1])
				}
				numDevices += 1
			} while (bytesToUInt16(msb: data[0], lsb: data[1]) != Outback.SUNSPEC_END_BLOCK_DID)

			deviceOffsetTable[0] -= 2
			deviceOffsetTable[numDevices] = addr

			parseDevices()
			
			readConfigDataFromDevice()
		}

        connected = true
		completionHandler(true)
	}
	
	func readConfigDataFromDevice()
	{
		firmwareVersion = getFirmwareVersion()
		dhcpEnabled = isDHCPEnabled() ?? false
		ipAddress = getIPAddress()
		gatewayIPAddress = getGatewayAddress()
		dns1IPAddress = getDNSAddress(whichDNS: 1)
		dns2IPAddress = getDNSAddress(whichDNS: 2)
		errors = getErrors() ?? 0
	}
	
	func getErrors() -> UInt16?
	{
		return getUInt16("Errors", offset: gatewayAddress)
	}
	
	override func getFirmwareVersion() -> String
	{
		if let data = readRegisters("Firmware Version", offset: gatewayAddress)
		{
			if data.count == 6
			{
				return "\(bytesToUInt16(msb: data[0], lsb: data[1])).\(bytesToUInt16(msb: data[2], lsb: data[3])).\(bytesToUInt16(msb: data[4], lsb: data[5]))"
			}
		}
		return ""
	}

	func isDHCPEnabled() -> Bool?
	{
		return getBoolean("DHCP Enabled", offset: gatewayAddress)
	}

	func getIPAddress() -> String
	{
		return readIPAddress("TCPIP Address")
	}

	func getGatewayAddress() -> String
	{
		return readIPAddress("TCPIP Gateway")
	}

	func getDNSAddress(whichDNS: Int) -> String
	{
		return readIPAddress(whichDNS == 1 ? "TCPIP DNS1" : "TCPIP DNS2")
	}

	func readIPAddress(_ register: String) -> String
	{
		if let data = readRegisters(register, offset: gatewayAddress)
		{
			if data.count == 4
			{
				return "\(data[0]).\(data[1]).\(data[2]).\(data[3])"
			}
		}
		return ""
	}
	
    override func getTypeName() -> String
    {
        return "Outback"
    }
    
	override func getCurrentBatteryVoltage() -> Float?
	{
		return getFloat("Battery Voltage", offset: gatewayAddress)
	}

	override func getCurrentBatteryTemperature() -> Float?
	{
		return getFloat("Battery Temperature", offset: gatewayAddress)
	}

	override func getCurrentBatteryStateOfCharge() -> Float?
	{
		if let voltage = getCurrentBatteryVoltage()
		{
			let soc = (((voltage - Outback.BATTERY_20_PERCENT_CHARGED_VOLTAGE) / Outback.BATTERY_SOC_VOLTAGE_DELTA) * 80) + 20

			return soc <= 100 ? soc : 100.0
		}
		return nil
	}

	override func getCurrentACOutputVoltage() -> Float?
	{
		return getFloat("AC Voltage", offset: inverters[0])
	}

	override func getCurrentPowerFromGenerator() -> Float?
	{
		var power: Float = 0

		if let current = getCurrentGeneratorCurrent(), let voltage = getCurrentACOutputVoltage()
		{
			power = current * voltage
		}

		return power
	}

	func getCurrentGeneratorCurrent() -> Float?
	{
		var generatorCurrent: Float = 0
		
		for inverter in inverters
		{
			if let current = getFloat("Generator Current", offset: inverter)
			{
				generatorCurrent += current
			}
		}
		
		return generatorCurrent
	}
	
	func getCurrentChargePower() -> Float?
	{
		var power: Float = 0.0

		if let current = getCurrentChargeCurrent(), let voltage = getCurrentACOutputVoltage()
		{
			power = current * voltage
		}

		return power
	}

	func getCurrentChargeCurrent() -> Float?
	{
		var chargeCurrent: Float = 0.0
		
		for inverter in inverters
		{
			if let current = getFloat("Charge Amps", offset: inverter)
			{
				chargeCurrent += current
			}
		}
		
		return chargeCurrent
	}
	
	override func getCurrentLoadPower() -> Float?
	{
		var power: Float = 0

		if let current = getCurrentLoadCurrent(), let voltage = getCurrentACOutputVoltage()
		{
			power = current * voltage
		}

		return power
	}

	func getCurrentLoadCurrent() -> Float?
	{
		var loadCurrent: Float = 0.0
		
		for inverter in inverters
		{
			if let current = getFloat("Load Amps", offset: inverter)
			{
				loadCurrent += current
			}
		}
		
		if loadCurrent == 0
		{
			let buyCurrent = getCurrentGeneratorCurrent() ?? 0.0
			let chargeCurrent = getCurrentChargeCurrent() ?? 0.0
			loadCurrent = buyCurrent - chargeCurrent
		}
		
		return loadCurrent
	}
	
//	func getChargerStateFromEachSolar() -> [String]
//	{
//		var statesArray = [String]()
//
//		for chargeControllerAddress in chargeControllers
//		{
//			let data = modbus.readRegisters(slaveID: 0xFF, startingRegister: chargeControllerAddress + Outback.CC_CHARGER_STATE_ADDRESS, numRegistersToRead: 1)
//			statesArray.append(chargerStates[Int(data[1])])
//		}
//
//		return statesArray
//	}
//
	func getCurrentPowerFromEachSolar() -> [UInt16]
	{
		var powerArray = [UInt16]()

		for chargeControllerAddress in chargeControllers
		{
			if let power = getUInt16("Solar Power", offset: chargeControllerAddress)
			{
				powerArray.append(power)
			}
			else
			{
				powerArray.append(0)
			}
		}

		return powerArray
	}

	override func getCurrentTotalPowerFromSolar() -> Float?
	{
		var power: Float = 0.0

		let powerArray = getCurrentPowerFromEachSolar()

		for individualPower in powerArray
		{
 			power += Float(individualPower)
		}

		return power
	}

//	func getDailyTimeInAbsorbForAllChargeControllers() -> [UInt16]
//	{
//		var absorbTimeArray = [UInt16]()
//
//		for chargeControllerAddress in chargeControllersConfig
//		{
//			let data = modbus.readRegisters(slaveID: 0xFF, startingRegister: chargeControllerAddress + Outback.CCCONFIG_LOG_DAILY_ABSORB_TIME_ADDRESS, numRegistersToRead: 1)
//			absorbTimeArray.append(bytesToUInt16(msb: data[0], lsb: data[1]))
//		}
//
//		return absorbTimeArray
//	}

	override func getCurrentBatteryPower() -> Float?
	{
		let solarPower = getCurrentTotalPowerFromSolar() ?? 0.0
		let chargePower = getCurrentChargePower() ?? 0.0
		let loadPower = getCurrentLoadPower() ?? 0.0
		let generatorPower = getCurrentPowerFromGenerator() ?? 0.0
		
		return (solarPower + chargePower) - (loadPower - (generatorPower - chargePower))
	}
	
	override func getCurrentBatteryCurrent() -> Float?
	{
		var batteryCurrent: Float = 0.0
		
		if let batteryPower = getCurrentBatteryPower(), let batteryVoltage = getCurrentBatteryVoltage()
		{
			batteryCurrent = batteryPower / batteryVoltage
		}

		return batteryCurrent
	}
	
	func getNumberOfChargeControllers() -> Int
	{
		return chargeControllers.count
	}
	
	func getNumberOfInverters() -> Int
	{
		return inverters.count
	}
	
	func parseDevices() -> Void
	{
		for deviceNum in 0..<deviceTable.count
		{
			switch deviceTable[deviceNum]
			{
				case Outback.SUNSPEC_COMMON_MODEL_BLOCK_DID:
//					print("SUNSPEC Common Model Block")
					break
					
				case Outback.SUNSPEC_OUTBACK_DID:
//					print("OutBack Gateway at address \(deviceOffsetTable[deviceNum])")
					gatewayAddress = deviceOffsetTable[deviceNum]
					break
					
				case Outback.SUNSPEC_OUTBACK_SYS_CONTROL_DID:
//					print("OutBack System Control")
					break
					
				case Outback.SUNSPEC_BASIC_CC_DID:
//					print("Basic Charge Controller at address \(deviceOffsetTable[deviceNum])")
					chargeControllers.append(deviceOffsetTable[deviceNum])
					break
					
				case Outback.SUNSPEC_OUTBACK_FM_CC_DID:
//					print("OutBack FM Charge Controller")
					chargeControllersConfig.append(deviceOffsetTable[deviceNum])
					break
					
				case Outback.SUNSPEC_INVERTER_SINGLE_DID:
//					print("Single Phase Inverter at address \(deviceOffsetTable[deviceNum])")
//					inverters.append(deviceOffsetTable[deviceNum])
					break
					
				case Outback.SUNSPEC_INVERTER_SPLIT_DID:
//					print("Split Phase Inverter")
					break
					
				case Outback.SUNSPEC_INVERTER_3PHASE_DID:
//					print("3 Phase Inverter")
					break
					
				case Outback.SUNSPEC_OUTBACK_FX_DID:
//					print("OutBack FX Inverter")
					inverters.append(deviceOffsetTable[deviceNum])
					break
					
				case Outback.SUNSPEC_OUTBACK_FX_CONFIG_DID:
//					print("OutBack FX Inverter Configuration")
					break
					
				case Outback.SUNSPEC_OUTBACK_GS_CONFIG_DID:
//					print("OutBack Radian Inverter Configuration")
					break
					
				case Outback.SUNSPEC_OUTBACK_GS_SPLIT_DID:
//					print("OutBack Radian Split Phase Inverter")
					break
					
				case Outback.SUNSPEC_OUTBACK_GS_SINGLE_DID:
//					print("OutBack Radian Single Phase Inverter")
					break
					
				case Outback.SUNSPEC_OUTBACK_FNDC_DID:
//					print("OutBack FLEXnet-DC Battery Monitor")
					break
					
				case Outback.SUNSPEC_OUTBACK_FNDC_CONFIG_DID:
//					print("OutBack FLEXnet-DC Battery Monitor Configuration")
					break
					
				case Outback.SUNSPEC_OUTBACK_STATISTICS_DID:
//					print("OutBack OPTICS Packet Statistics")
					break
					
				case Outback.SUNSPEC_END_BLOCK_DID:
//					print("SunSpec End Block")
					break
					
				default:
					break
			}
		}
	}
	
	func getSunSpecID()-> UInt32?
	{
		return getUInt32("Sunspec ID")
	}
}
