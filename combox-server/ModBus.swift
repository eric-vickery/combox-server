//
//  ModBus.swift
//  Solar Monitor
//
//  Created by Eric Vickery
//

import Foundation
import SwiftSocket

class ModBus
{
	let readRegisterCommand: UInt8 = 0x03
	var headerData:[UInt8] = [0x01, 0x15, 0x00, 0x00, 0x00, 0x06]
	
	var client: TCPClient!
	
	func connect(address: String, port: Int32) -> Bool
	{
		client = TCPClient(address: address, port: port)

		switch client.connect(timeout: 10)
		{
		case .success:
			return true
		case .failure(let error):
			print(error)
			return false
		}
	}
	
	func readRegisters(slaveID: UInt8, startingRegister: UInt16, numRegistersToRead: Int) -> [UInt8]
	{
		var receivedData = [UInt8]()

		if (client != nil)
		{
			let dataToSend = buildPacketToSend(headerData: headerData, slaveID: slaveID, startingRegister: startingRegister, numRegistersToRead: numRegistersToRead)

			switch client.send(data: dataToSend)
			{
			case .success:
				guard let header = client.read(9, timeout: 5) else
				{
					break
				}

				if header[7] > 0x80
				{
					break
				}

				guard let data = client.read(Int(header[8]), timeout: 5) else
				{
					break
				}

				receivedData.append(contentsOf: data)

			case .failure(let error):
				print(error)
			}
		}
		return receivedData
	}
	
	func buildPacketToSend(headerData: [UInt8], slaveID: UInt8, startingRegister: UInt16, numRegistersToRead: Int) -> [UInt8]
	{
		var combinedData = [UInt8]()
		
		combinedData.append(contentsOf: headerData)
		combinedData.append(slaveID)
		combinedData.append(readRegisterCommand)
		combinedData.append(UInt8(startingRegister >> 8))
		combinedData.append(UInt8(startingRegister & 0x00FF))
		combinedData.append(0x00)
		combinedData.append(UInt8(numRegistersToRead))
		
		return combinedData
	}
	
	func getString(slaveID: UInt8, startingRegister: UInt16, numRegistersToRead: Int) -> String?
	{
		let data = readRegisters(slaveID: slaveID, startingRegister: startingRegister, numRegistersToRead: numRegistersToRead)
		
		let strippedData = stripTrailingCrud(data: data)
		
		if let response = String(bytes: strippedData, encoding: .utf8)
		{
			return response
		}
		else
		{
			return nil
		}
	}
	
	func stripTrailingCrud(data: [UInt8]) -> [UInt8]
	{
		var newArray = [UInt8]()
		
		for element in data
		{
			if element != 255
			{
				newArray.append(element)
			}
		}
		
		return newArray
	}
}
