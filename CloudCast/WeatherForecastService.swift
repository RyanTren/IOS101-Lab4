//
//  WeatherForecastService.swift
//  CloudCast
//
//  Created by Ryan on 10/7/23.
//

import Foundation
import SwiftUI
import UIKit


struct CurrentWeatherForecast: Decodable{
    let windspeed: Double
    let windDirection: Double
    let temperature: Double
    let weatherCodeRaw: Int
    var weatherCode : WeatherCode{
        return WeatherCode(rawValue: weatherCodeRaw) ?? .clearSky
    }
    
    private enum CodingKeys: String, CodingKey{
        case windspeed = "windspeed"
        case windDirection = "winddirection"
        case temperature = "temperature"
        case weatherCodeRaw = "weathercode"
    }
}

struct WeatherAPIResponse: Decodable{
    let currentWeather: CurrentWeatherForecast
    
    private enum CodingKeys: String, CodingKey{
        case currentWeather = "current_weather"
    }
}

class WeatherForecastService {
  static func fetchForecast(latitude: Double,
                            longitude: Double,
                            completion: ((CurrentWeatherForecast) -> Void)? = nil) {
      
    let parameters = "latitude=\(latitude)&longitude=\(longitude)&current_weather=true&temperature_unit=fahrenheit&timezone=auto&windspeed_unit=mph"
    let url = URL(string: "https://api.open-meteo.com/v1/forecast?\(parameters)")!
    // create a data task and pass in the URL
      let task = URLSession.shared.dataTask(with: url) { data, response, error in
          // this closure is fired when the response is received
          guard error == nil else {
              assertionFailure("Error: \(error!.localizedDescription)")
              return
          }
          guard let httpResponse = response as? HTTPURLResponse
          else {
              assertionFailure("Invalid response")
              return
          }
          guard let data = data, httpResponse.statusCode == 200 else {
              assertionFailure("Invalid response status code: \(httpResponse.statusCode)")
              return
          }
          
          let decoder = JSONDecoder()
          let response = try! decoder.decode(WeatherAPIResponse.self, from: data)
          DispatchQueue.main.async{
              completion?(response.currentWeather)
          }
          
          let forecast = parse(data: data)
          
          DispatchQueue.main.async{
              completion?(forecast)
          }
      }
    task.resume() // resume the task and fire the request
  }
    private static func parse(data: Data) -> CurrentWeatherForecast{
        let jsonDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let currentWeather = jsonDictionary["current_weather"] as! [String: Any]
        
        let windSpeed = currentWeather["windspeed"] as! Double
        let windDirection = currentWeather["winddirection"] as! Double
        
        let temperature = currentWeather["temperature"] as! Double
        
        let weatherCodeRaw = currentWeather["weathercode"] as! Int
        return CurrentWeatherForecast(windspeed: windSpeed, windDirection: windDirection, temperature: temperature, weatherCodeRaw: weatherCodeRaw)
    }
}
