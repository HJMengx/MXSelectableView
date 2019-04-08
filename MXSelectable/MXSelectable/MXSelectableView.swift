//
//  MXSelectableView.swift
//  MXSelectable
//
//  Created by 贺靖 on 2019/4/4.
//  Copyright © 2019 贺靖. All rights reserved.
//

import UIKit

fileprivate let buttonSize : CGFloat = 40
// 获取顶部导航栏的高度
fileprivate let topHeight = UIApplication.shared.statusBarFrame.size.height + 44.0
// 获取系统的底部高度
fileprivate let bottomHeight = UITabBarController.init().tabBar.bounds.size.height
// Picker默认高度
fileprivate let pickerHeight : CGFloat = 175

class MXSelectableView: UIView {
    
    weak var contentView : UIPickerView?
    
    weak var desView : UIView?
    
    var mainContent : [String]!
    
    var subContents : [[String : [String]]]?
    
    var isGroup : Bool!
    
    var rowHeight : CGFloat!
    
    var isShow : Bool = false
    
    var selectedCallBack : ((_ selected : [String])->Void)?
    
    fileprivate var showAnimation : CAAnimationGroup = CAAnimationGroup.init()
    
    fileprivate var dismissAnimation : CAAnimationGroup = CAAnimationGroup.init()
    
    fileprivate var selectedIndexes : [Int] = [Int]()
    
    // MARK: 初始化方法
    init(frame: CGRect, mainContent:[String], subContents : [[String : [String]]]?, isGroup : Bool=false, rowHeight: CGFloat=40, tap : Bool=true, selectedCallBack: ((_ selected : [String])->Void)?) {
        super.init(frame: frame)
        self.mainContent = mainContent
        self.subContents = subContents
        self.isGroup = isGroup
        self.rowHeight = rowHeight
        self.selectedCallBack = selectedCallBack
        // 初始化选中数组, 默认全是第一个
        var total = 1
        if subContents != nil {
            total = self.subContents!.count + 1
        }
        
        for _ in 0..<total {
            self.selectedIndexes.append(0)
        }
        if tap {
            self.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(MXSelectableView.tapForHidden(_:))))
        }
        // 通过颜色设置透明度
        self.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.3);
        // 初始化Layer
        self.initContainer()
        // 初始化控件
        self.initViews()
        // 初始化动画
        self.initAnimation()
    }
    // MARK: 点击消失
    @objc func tapForHidden(_ gesture : UIGestureRecognizer){
        self.dismiss()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(mainContent:[String], subContents : [[String : [String]]]?, isGroup : Bool=false, rowHeight: CGFloat=40, selectedCallBack: ((_ selected : [String])->Void)?) {
        self.init(frame: UIApplication.shared.keyWindow!.bounds, mainContent: mainContent, subContents: subContents, isGroup: isGroup, rowHeight: rowHeight, selectedCallBack: selectedCallBack)
    }
    
    // MARK: 绘制周边圆角等属性
    fileprivate func initContainer(){
        if self.desView == nil {
            let container = UIView.init(frame: CGRect.init(x: 20, y: UIApplication.shared.keyWindow!.bounds.height - (pickerHeight + buttonSize + 10.0), width: UIApplication.shared.keyWindow!.bounds.width - 40, height: pickerHeight + buttonSize))
            self.desView = container
            self.desView!.layer.borderWidth = 1
            self.desView!.layer.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.4).cgColor
            self.desView!.layer.cornerRadius = 10
            self.desView!.layer.masksToBounds = true
            self.addSubview(self.desView!)
        }
    }
    
    // initView
    fileprivate func initViews(){
        if self.contentView == nil {
            let pickerView = UIPickerView.init(frame: CGRect.init(x: 0, y: 0, width: self.desView!.bounds.width, height: pickerHeight))
            
            pickerView.delegate = self
            pickerView.dataSource = self
            
            self.contentView = pickerView
            // submitButton
            let submitButton = self.submitButton()
            
            self.desView!.addSubview(pickerView)
            self.desView!.addSubview(submitButton)
        }
    }
    
    fileprivate func cancelButton() -> UIButton {
        let cancelButton = UIButton.init(frame: CGRect.init(x: 30, y: 10, width: buttonSize, height: buttonSize))
        
        cancelButton.backgroundColor = UIColor.lightGray
        
        cancelButton.setTitle("取消", for: UIControl.State.normal)
        
        cancelButton.addTarget(self, action: #selector(MXSelectableView.dismiss), for: UIControl.Event.touchUpInside)
        
        return cancelButton
    }
    
    fileprivate func submitButton() -> UIButton  {
        let submitButton = UIButton.init(frame: CGRect.init(x: 0, y: pickerHeight, width: self.desView!.bounds.size.width, height: buttonSize))
        
        submitButton.setTitle("确认", for: UIControl.State.normal)
        
        submitButton.backgroundColor = UIColor.init(red: 10 / 255, green: 96 / 255, blue: 255 / 255, alpha: 1)
        
        submitButton.addTarget(self, action: #selector(MXSelectableView.submit), for: UIControl.Event.touchUpInside)
        
        return submitButton
    }
    
    fileprivate func initAnimation() {
        /** 出现动画 */
        // 缩放动画
        let sizeShowAnimation = CAKeyframeAnimation.init(keyPath: "position.y")
        sizeShowAnimation.values = [self.bounds.height + self.desView!.bounds.height, self.bounds.height, self.bounds.height - (pickerHeight + buttonSize + 10.0)]
//        sizeShowAnimation.keyTimes = [0.1, 0.7, 1.0]
        
        sizeShowAnimation.autoreverses = false
        
        sizeShowAnimation.timingFunctions = [CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeOut),CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.default)]
        
        sizeShowAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        sizeShowAnimation.calculationMode = CAAnimationCalculationMode.linear
        
        sizeShowAnimation.isRemovedOnCompletion = false
        // 透明度动画
        let alphaShowAnimation = CABasicAnimation.init(keyPath: "opacity")
        alphaShowAnimation.fromValue = 0
        alphaShowAnimation.toValue = 1
        
        self.showAnimation.animations = [sizeShowAnimation, alphaShowAnimation]
        self.showAnimation.isRemovedOnCompletion = false
        self.showAnimation.duration = 0.5
        /** 消失动画 */
        // 缩放动画
        let sizeDismissAnimation = CAKeyframeAnimation.init(keyPath: "position.y")
        
        sizeDismissAnimation.values = [self.bounds.height - self.desView!.bounds.height, self.bounds.height - buttonSize, self.bounds.height + self.desView!.bounds.height]
        
        sizeDismissAnimation.keyTimes = [0.1, 0.7, 1.0]
        
        sizeDismissAnimation.autoreverses = false
        
        sizeDismissAnimation.timingFunctions = [CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeOut),CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.default)]
        
        sizeShowAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        sizeShowAnimation.calculationMode = CAAnimationCalculationMode.linear
        
        sizeShowAnimation.isRemovedOnCompletion = false
        // 透明度动画
        let alphaDismissAnimation = CABasicAnimation.init(keyPath: "opacity")
        alphaDismissAnimation.fromValue = 1
        alphaDismissAnimation.toValue = 0
        
        // 设置基本属性
        self.dismissAnimation.animations = [sizeDismissAnimation, alphaDismissAnimation]
        self.dismissAnimation.isRemovedOnCompletion = false
        self.dismissAnimation.duration = 0.5
        self.dismissAnimation.delegate = self
        self.dismissAnimation.setValue("dismiss", forKey: "type")
    }
    
    // 展示
    func show() {
        if self.isShow {
            return
        }
        self.isShow = true
        // 添加View
        UIApplication.shared.keyWindow!.addSubview(self)
        self.desView!.layer.add(self.showAnimation, forKey: "show")
    }
    
    @objc func dismiss() {
        self.desView!.layer.add(self.dismissAnimation, forKey: "dismiss")
    }
    
    // 获取选中值的方法
    fileprivate func getSelectedValue(with component : Int) -> String {
        var value : String!
        
        value = self.mainContent[self.selectedIndexes[component]]
        
        if component == 0 {
            value = self.mainContent[self.selectedIndexes[component]]
        }else{
            // 前一个模块的选中值
            for index in 1..<component {
                value = self.subContents![index - 1][value]![self.selectedIndexes[index]]
            }
            value = self.subContents![component - 1][value]![self.selectedIndexes[self.selectedIndexes.count - 1]]
        }
        return value
    }
    
    // 确认按钮
    @objc fileprivate func submit() {
        var selectedValues = [String]()
        // 第一个元素进行赋值
        selectedValues.append(self.getSelectedValue(with: 0))
        
        for index in 1..<self.selectedIndexes.count {
            selectedValues.append(self.getSelectedValue(with: index))
        }
        // 执行回调
        if self.selectedCallBack != nil {
            self.selectedCallBack!(selectedValues)
        }
        
        self.dismiss()
    }
    
    // 取消按钮
    fileprivate func cancel() {
        self.dismiss()
    }
    
    // MARK: 加载Json数据
    // MARK: 加载Json数据
    fileprivate func loadJson() {
        var provinces : [String] = [String]()
        var cities : [String : [String]] = [String : [String]]()
        var areas : [String : [String]] = [String : [String]]()
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

// MARK: 代理以及数据源
extension MXSelectableView : UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if self.subContents != nil {
            return self.subContents!.count + 1
        }else{
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var count = self.mainContent.count
        
        if self.subContents != nil && component != 0{
            // 第一个模块的值
            var value : String = self.mainContent[self.selectedIndexes[0]]
            
            // 前一个模块的选中值
            for index in 1..<component {
                value = self.subContents![index - 1][value]![self.selectedIndexes[index]]
            }
            
            if self.subContents![component - 1][value] == nil {
                count = 0
            }else{
                count = self.subContents![component - 1][value]!.count
            }
        }
        return count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as? UILabel
        
        // 第一个模块的值
        var value : String = self.mainContent[self.selectedIndexes[0]]
        
        if self.subContents != nil && component != 0 {
            // 前一个模块的选中值
            for index in 1..<component {
                value = self.subContents![index - 1][value]![self.selectedIndexes[index]]
            }
            value = self.subContents![component - 1][value]![row]
        }else{
            value = self.mainContent[row]
        }
        if label == nil {
            label = UILabel()
            
            label!.font = UIFont.systemFont(ofSize: 16)
            label!.textAlignment = .center
        }
        
        label!.text = value
        
        return label!
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return self.rowHeight
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // 设置选中
        self.selectedIndexes[component] = row
        // 前面的部分刷新都需要更新后面的Component
        if self.subContents != nil {
            let startIndex = component + 1
            for refreshIndex in startIndex ..< self.subContents!.count + 1 {
                pickerView.reloadComponent(refreshIndex)
                pickerView.selectRow(0, inComponent: refreshIndex, animated: true)
            }
        }
    }
}

// MARK: 动画代理
extension MXSelectableView : CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        let value = anim.value(forKey: "type") as? String
        if value != nil && value == "dismiss"  {
            // dismiss
            self.isShow = false
            self.removeFromSuperview()
        }else{
            // show
            
        }
    }
}
