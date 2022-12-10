//
//  ModbusRegister.swift
//  Solar Monitor
//
//  Created by Eric Vickery
//

import Foundation
import ObjectMapper

class ModbusRegister: Mappable
{
	var address: UInt16 = 0
	var name = ""
	var type = ""
	var length: Int = 0
	var readOnly = true
	var units = ""
	var scale: Float = 1.0
	var offset: Float = 0.0
	
	required init?(map: Map)
	{
	}
	
	func mapping(map: Map)
	{
		var addressString = ""

		addressString	<- map["address"]
		name			<- map["name"]
		type			<- map["type"]
		length			<- map["length"]
		readOnly		<- map["readOnly"]
		units			<- map["units"]
		scale			<- map["scale"]
		offset			<- map["offset"]

		let index = addressString.index(addressString.startIndex, offsetBy: 2)
		let subAddress = addressString[index...]
		address = UInt16(subAddress, radix: 16)!
	}
}
