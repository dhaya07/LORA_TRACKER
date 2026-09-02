//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audioplayers_darwin
import battery_plus
import flutter_blue_plus_darwin
import geolocator_apple
import package_info_plus
import record_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioplayersDarwinPlugin.register(with: registry.registrar(forPlugin: "AudioplayersDarwinPlugin"))
  BatteryPlusMacosPlugin.register(with: registry.registrar(forPlugin: "BatteryPlusMacosPlugin"))
  FlutterBluePlusPlugin.register(with: registry.registrar(forPlugin: "FlutterBluePlusPlugin"))
  GeolocatorPlugin.register(with: registry.registrar(forPlugin: "GeolocatorPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  RecordMacOsPlugin.register(with: registry.registrar(forPlugin: "RecordMacOsPlugin"))
}
