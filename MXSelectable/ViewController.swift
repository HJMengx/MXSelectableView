//
//  ViewController.swift
//  MXSelectable
//
//  Created by 贺靖 on 2019/4/4.
//  Copyright © 2019 贺靖. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var provinces : [String] = [String]()
    var cities : [String : [String]] = [String : [String]]()
    var areas : [String : [String]] = [String : [String]]()
    
    var picker : MXSelectableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadJson()
        self.view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(showPicker(gesture:))))
    }

    @objc func showPicker(gesture : UITapGestureRecognizer) {
        
//        let point = gesture.location(in: self.view)
        
        if self.picker != nil && self.view.subviews.contains(self.picker) {
            return
        }
        // mainContent: self.provinces, subContents: [self.cities, self.areas], isGroup: true
        self.picker = MXSelectableView.init(mainContent: provinces, subContents: [cities, areas], isGroup: true, selectedCallBack: { (result : [String]) in
            print(result)
        })
        
        picker.show()
    }
    
    // MARK: 加载Json数据
    fileprivate func loadJson() {
        do {
            if let file = Bundle.main.url(forResource: "data", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let object = json as? [String: Any] {
                    // 获取所有省份
                    for value in (object["86"] as! [String : Any]).values {
                        provinces.append(value as! String)
                    }
                    
                    let provinceKeys = (object["86"] as! [String : Any]).keys
                    // 获取所有的城市
                    for proKey in provinceKeys {
                        let citiesDict = object[proKey] as? [String : Any]
                        if citiesDict == nil {
                            continue
                        }
                        var tempCities = [String]()
                        
                        let proValue = (object["86"] as! [String : Any])[proKey]
                        
                        for value in citiesDict!.values {
                            if !cities.keys.contains(proValue as! String) {
                                cities[proValue as! String] = tempCities
                            }
                            tempCities.append(value as! String)
                            cities[proValue as! String]?.append(value as! String)
                        }
                        // 获取所有的区号
                        for cityKey in citiesDict!.keys {
                            let tempArea = [String]()
                            let areaDict = (object[cityKey] as? [String: Any])
                            if areaDict == nil {
                                continue
                            }
                            for areaValue in areaDict!.values {
                                if !areas.keys.contains(citiesDict![cityKey] as! String) {
                                    areas[citiesDict![cityKey] as! String] = tempArea
                                }
                                areas[citiesDict![cityKey] as! String]?.append(areaValue as! String)
                            }
                        }
                    }
                } else if let object = json as? [Any] {
                    // json is an array
                    print("array: \(object)")
                } else {
                    print("JSON is invalid")
                }
            } else {
                print("no file")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

