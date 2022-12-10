//
//  Combox.swift
//  Solar Monitor
//
//  Created by Eric Vickery
//

import Foundation
import CocoaAsyncSocket

class Combox: BaseDevice, GCDAsyncUdpSocketDelegate
{
	static let UDP_PORT: UInt16 = 53152
	static let GRID_TO_LOAD = 0x0001
	static let GEN_TO_LOAD = 0x0002
	static let RESERVED = 0x0004
	static let BATT_TO_GRID = 0x0008
	static let GRID_TO_BATT = 0x0010
	static let GEN_TO_BATT = 0x0020
	static let PV_TO_BATT = 0x0040
	static let PV_TO_GRID = 0x0080
	static let BATT_TO_LOAD = 0x0100
	
	var sock: GCDAsyncUdpSocket?
	var addressCompletionHandler: ((String?) -> Void)?
	
	override func connect(address: String?, port: Int32, completionHandler: @escaping (Bool) -> Void)
	{
		if self.modbus == nil
		{
			self.modbus = ModBus()
		}
		
		// If the address was passed in then use it, otherwise go find the Combox
		if let address = address
		{
			if let modbus = self.modbus
			{
                let didConnect = modbus.connect(address: address, port: port)
                self.connected = didConnect
				completionHandler(didConnect)
			}
			else
			{
                self.connected = false
				completionHandler(false)
			}
		}
		else
		{
			findCombox() { address in
				if let modbus = self.modbus, let address = address
				{
                    let didConnect = modbus.connect(address: address, port: port)
                    self.connected = didConnect
                    completionHandler(didConnect)
				}
				else
				{
                    self.connected = false
					completionHandler(false)
				}
			}
		}
	}

	func findCombox(completionHandler: @escaping (_ address: String?) -> Void)
	{
		if sock == nil
		{
			sock = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
		}
		
		do {
			if let sock = sock
			{
				addressCompletionHandler = completionHandler

				try sock.bind(toPort: Combox.UDP_PORT)
				try sock.enableBroadcast(true)
				try sock.beginReceiving()
			}
		}
		catch
		{
			print("Error setting up UDP")
		}
	}

	func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?)
	{
		let host = GCDAsyncUdpSocket.host(fromAddress: address)

		if let host = host
		{
			if !host.contains("::ffff")
			{
				print("incoming message: \(data) from host \(host)")
				sock.close()
				if let addressCompletionHandler = addressCompletionHandler
				{
					addressCompletionHandler(host)
				}
			}
		}

	}
	
    override func getTypeName() -> String
    {
        return "Combox"
    }
    
	override func getCurrentBatteryVoltage() -> Float?
	{
		return getFloat("Battery Bank 1 Voltage")
	}
	
	override func getCurrentBatteryCurrent() -> Float?
	{
		return getFloat("Battery Bank 1 Current")
	}

	override func getCurrentBatteryPower() -> Float?
	{
		var batteryPower: Float = 0.0
		
		if let batteryCurrent = getCurrentBatteryCurrent(), let voltage = getCurrentBatteryVoltage()
		{
			batteryPower = batteryCurrent * voltage
		}
		return batteryPower
	}
	
	override func getCurrentBatteryTemperature() -> Float?
	{
		return getFloat("Battery Bank 1 Temperature")
	}

	override func getCurrentBatteryStateOfCharge() -> Float?
	{
		return getFloat("Battery Bank 1 SOC")
	}

	override func getCurrentACOutputVoltage() -> Float?
	{
		return getFloat("Load Voltage")
	}

	override func getCurrentACOutputFrequency() -> Float?
	{
		return getFloat("Load Frequency")
	}
	
	override func getCurrentLoadOutputPower() -> Float?
	{
		return getFloat("Load Output Power")
	}
	
	override func getCurrentLoadPower() -> Float?
	{
		return getFloat("Load Power")
	}
	
	override func getCurrentLoadPowerApparent() -> Float?
	{
		return getFloat("Load Power (APP)")
	}
	
	override func getCurrentPowerFromGenerator() -> Float?
	{
		return getFloat("XW Generator Power")
	}

	override func getCurrentGeneratorVoltage() -> Float?
	{
		return getFloat("XW Generator Voltage")
	}
	
	override func getCurrentGeneratorFrequency() -> Float?
	{
		return getFloat("XW Generator Frequency")
	}
	
	override func getCurrentTotalPowerFromSolar() -> Float?
	{
		return getFloat("PV Total Power")
	}

	override func getCurrentHarvestPowerFromSolar() -> Float?
	{
		return getFloat("PV Harvest Power")
	}
	
	func getLastAbsorptionExitTime() -> Int32?
	{
		return getInt("Last Absorption Exit Time")
	}
}
