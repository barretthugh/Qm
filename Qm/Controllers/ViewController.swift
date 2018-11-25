//
//  ViewController.swift
//  Qm
//
//  Created by barrett on 23/11/2018.
//  Copyright © 2018 barrett. All rights reserved.
//

import UIKit
import Charts
import Alamofire
import SwiftyJSON
import SVProgressHUD

class ViewController: UIViewController {
    
//    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var barChart: BarChartView!
    weak var axisFormatDelegate: IAxisValueFormatter?
    
    let ts_URL = "http://api.tushare.pro"
    let ts_token = "8e4cece77b3720b2c8013a064fb0bfc2b725f67dce5bc20d2e0122b2"
    
    lazy var ts_params : [String : Any] = [
        "token": ts_token,
    ]
    
    var trading: String = ""
    
    let pctStatistic = StatisticDataModel()
    
    var basic_result = [String: [String:Any]]()
    var daily_result = [String: [String:Any]]()
    var daily_statistic = [String: Int]()
    
    let statisticLabel = ["≤-7", "-7∼-5", "-5∼-3", "-3∼0", "0", "0∼3", "3∼5", "5∼7", "≥7"]
    var statistic = [String: BarChartDataEntry]()
    var total = [BarChartDataEntry]()

    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        
        axisFormatDelegate = self
        
        barChart.chartDescription?.text = ""
        
        
//        trading = "20181123"
        
        fetchData()
        
    }
    
    func get_TradeDay(completionHandler: @escaping (NSDictionary?, Error?) -> ()) {
        getTradeDay(url: ts_URL, completionHandler: completionHandler)
    }
    
    func getTradeDay(url: String, completionHandler: @escaping (NSDictionary?, Error?) -> ()) {
        let params = ["start_date": "20180101", "end_date": "20181231"]
        let fields = "cal_date, is_open, pretrade_date"
        let parameters = set_params(ts_params: ts_params, api_name: "trade_cal", fields: fields, params: params)
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON  {
            response in
            switch response.result {
            case .success(let value):
                completionHandler(value as? NSDictionary, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    func fetchData() {
        
        self.get_basic() { basic, error in
            let basic_js: JSON = JSON(basic!)
            for j in basic_js["data"]["items"] {
                self.basic_result[j.1[0].stringValue] = ["name": j.1[1].stringValue, "area": j.1[2].stringValue, "industry": j.1[3].stringValue]
            }
            self.get_TradeDay() { days, error in
                let date = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                let today = formatter.string(from: date)

                let js: JSON = JSON(days!)
                for day in js["data"]["items"] {
                    if day.1[0].stringValue == today {
                        if day.1[1] == 1 {
                            self.trading = today
                        } else {
                            self.trading = day.1[2].stringValue
                        }
                    }
                }
//                self.dateLabel.text = self.trading
                
                
                
                self.get_daily(tradeDay: self.trading) { daily, daily_error in
                    let daily_js = JSON(daily!)
                    for i in daily_js["data"]["items"] {
                        self.daily_result[i.1[0].stringValue] = [
                            "open": i.1[1].floatValue.roundTo(places: 2),
                            "high": i.1[2].floatValue.roundTo(places: 2),
                            "low": i.1[3].floatValue.roundTo(places: 2),
                            "close": i.1[4].floatValue.roundTo(places: 2),
                            "pre_close": i.1[5].floatValue.roundTo(places: 2),
                            "pct_change": i.1[6].floatValue.roundTo(places: 2),
                            "vol": i.1[7].floatValue.roundTo(places: 2),
                            "name": self.basic_result[i.1[0].stringValue]!["name"]!,
                            "area": self.basic_result[i.1[0].stringValue]!["area"]!,
                            "industry": self.basic_result[i.1[0].stringValue]!["industry"]!,
                            "label": self.pctStatistic.pctStatistic(pct_change: i.1[6].floatValue.roundTo(places: 2))
                        ]
                    }
                    for stock in self.daily_result {
                        //                    let ret = self.pctStatistic.pctStatistic(pct_change: stock.value["pct_change"] as! Float)
                        let ret = stock.value["label"] as! String
                        if Array(self.daily_statistic.keys).contains(ret) {
                            self.daily_statistic[ret] = self.daily_statistic[ret]! + 1
                        } else {
                            self.daily_statistic[ret] = 1
                        }
                    }
                    var num = 1.0
                    for s in self.statisticLabel {
                        
                        //                    self.statistic[s] = BarChartDataEntry(x: num, y: Double(self.daily_statistic[s]!))
                        
                        self.total.append(BarChartDataEntry(x: num, y: Double(self.daily_statistic[s]!)))
                        
                        num += 1
                    }
                    self.updateChartData()
                }
            }
        }
    }
    
    func updateChartData() {
        let chartDataSet = BarChartDataSet(values: total, label: nil)
        
        let chartData = BarChartData(dataSet: chartDataSet)
        
        var colors = [UIColor]()
        
        for s in self.statisticLabel {
            if s.contains("-") {
                colors.append(UIColor.green)
            } else {
                colors.append(UIColor.red)
            }
        }
        
        chartDataSet.colors = colors
        
        barChart.data = chartData
        
        let xaxis = barChart.xAxis
        xaxis.valueFormatter = axisFormatDelegate
        
        barChart.legend.enabled = false
        
        barChart.leftAxis.axisMinimum = 0
        barChart.rightAxis.axisMinimum = 0
        
        SVProgressHUD.dismiss()
    }
    
    func set_params(ts_params: [String: Any], api_name: String, fields: String, params: [String:String] = [:]) -> [String: Any] {
        var dict = ts_params
        dict["api_name"] = api_name
        dict["fields"] = fields
        if params.count != 0 {
            dict["params"] = params
        }
        return dict
    }
    
    func get_daily(tradeDay: String, completionHandler: @escaping (NSDictionary?, Error?) -> ()) {
        dailyUpdate(url: ts_URL, tradeDay: tradeDay, completionHandler: completionHandler)
    }
    
    func dailyUpdate(url: String, tradeDay: String, completionHandler: @escaping (NSDictionary?, Error?) -> ()) {
        
        let fields = "ts_code, open, high, low, close, pre_close, pct_change, vol"
        let api_name = "daily"
        let params = ["trade_date": tradeDay]
        let parameters = set_params(ts_params: ts_params, api_name: api_name, fields: fields, params: params)
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON  {
            response in
            switch response.result {
            case .success(let value):
                completionHandler(value as? NSDictionary, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    func get_basic(completionHandler: @escaping (NSDictionary?, Error?) -> ()) {
        basicUpdate(url: ts_URL, completionHandler: completionHandler)
    }
    
    func basicUpdate(url: String, completionHandler: @escaping (NSDictionary?, Error?) -> ()) {
        let fields = "ts_code,name,area,industry"
        let api_name = "stock_basic"
        let parameters = set_params(ts_params: ts_params, api_name: api_name, fields: fields)
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON {
            response in
            switch response.result {
            case .success(let value):
                completionHandler(value as? NSDictionary, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
}

extension Float {
    func roundTo(places:Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

extension ViewController: IAxisValueFormatter {
    func stringForValue (_ value: Double, axis: AxisBase?) -> String {
//        let statistic = ["≤-7": 1.0, "-7∼-5": 2.0, "-5∼-3": 3.0, "-3∼0": 4.0, "0": 5.0, "0∼3": 6.0]
        switch (value) {
        case 9.0 :
            return "≥7"
        case 8.0 :
            return "5∼7"
        case 7.0 :
            return "3∼5"
        case 6.0 :
            return "0∼3"
        case 4.0 :
            return "-3∼0"
        case 3.0 :
            return "-5∼-3"
        case 2.0 :
            return "-7∼-5"
        case 1.0 :
            return "≤-7"
        default:
            return "0"
        }
        
    }
}
