//
//  StatisticDataModel.swift
//  Qm
//
//  Created by barrett on 25/11/2018.
//  Copyright © 2018 barrett. All rights reserved.
//

import Foundation

class StatisticDataModel {
//    var area: String = ""
//    var industry: String = ""
    var pct_change: String = ""
    
    func pctStatistic(pct_change: Float) -> String {
        switch (pct_change) {
        case 7 ... 11 :
            return "≥7"
        case 5 ... 6.99 :
            return "5∼7"
        case 3 ... 4.99 :
            return "3∼5"
        case 0.01 ... 2.99 :
            return "0∼3"
        case -2.99 ... -0.01 :
            return "-3∼0"
        case -4.99 ... -3 :
            return "-5∼-3"
        case -6.99 ... -5 :
            return "-7∼-5"
        case -11 ... -7 :
            return "≤-7"
        default:
            return "0"
        }
    }
}
