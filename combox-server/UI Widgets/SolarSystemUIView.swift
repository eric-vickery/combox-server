//
//  SolarSystemUIView.swift
//  SolarMonitor
//
//  Created by Eric Vickery on 4/2/20.
//  Copyright © 2020 Eric Vickery. All rights reserved.
//

import SwiftUI

struct SolarSystemUIView: View {
    @ObservedObject var device: BaseDevice

    var body: some View {
        VStack {
            Text(device.getTypeName())
            .font(.largeTitle)
            .bold()
            HStack(spacing: 20) {
                Text("Available Solar")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.availableSolarPower + " W")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Solar Harvest")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.currentSolarPower + " W")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Load")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.loadPower + " W")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Battery Voltage")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.batteryVoltage + " V")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Battery SOC")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.batterySOC + "%")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Battery Amps")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.batteryAmps + " A")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Battery Power")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.batteryPower + " W")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Battery Temperature")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.batteryTemperatureC + " C / " + device.batteryTemperatureF + " F")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 20) {
                Text("Charger State")
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                Text(device.chargerState)
                    .font(.headline)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

//struct SolarSystemUIView_Previews: PreviewProvider {
//    static var baseDevice = BaseDevice.loadFromFile(deviceName: "Combox", testMode: true)
//    static var previews: some View {
//        SolarSystemUIView(device: baseDevice!)
//    }
//}
