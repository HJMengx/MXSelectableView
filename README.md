### 为什么要写个这样的选择器

开发中, 我们经常需要用到选择器, 比如时间的选择, 地址的选择等等, 我们不能每一次都是重复写类似的代码来实现不同的效果, 这样不仅效率低, 也难以维护(可以通过中间者去接收不同的参数来生成不同的PickerView), 这里我只是通过构造函数去初始化不同的`PickerView`.

---

**这里我选取的例子是地址选择器, 通过传入指定格式的数据就可以动态生成不同的PickerView**

![](https://upload-images.jianshu.io/upload_images/5393797-6d638104419ec06e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

以上是最后的实现效果, 来看一下实现过程.

#### 实现思路

归根结底, 动态的生成`PickerView`只不过是数据的不同导致的, 那么数据源肯定是从外界传入的(这个地方我开始想的是能不能数据格式都任意, 这样可以达到最大程度的自由, 但是被现实打脸了, 在实现`PickerViewDatasource`方法的时候, 无法正确匹配上, 除非交给外界类去实现, 但是代码量其实没有减少, 最终选择了在规定了数据格式的前提下最大程度的实现自由度, 大家如果有好的方法教教我).

我设置的数据格式是:

`mainContent`: 代表第一个`Component`的数据, 如果只有一个`Component`, 那么只需要设置这一个数据就够了.
`subContents`: 后面`Component` 的数据, 可选类型, 有多个区域则需要设置, 后续的判断都会基于这个值是否是`nil`.

`mainContent` 是一个一维的 `String` 数组.
`subContents`是一个`[[String : [String]]]`的复合结构, 它的每一个维度代表一个`Component`,  它的每一个`key`是前一个`Component`的值, 这样就可以最大程度的自由化了, 只要数据格式满足, 就可以实现(我能想到的).

#### 代码部分

**1. 找到每一个位置对应的值**

```Swift
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
``` 

通过循环的方式去取出对应`Component`的值,  因为第一个`Component`是直接可以取到的, 后面的`Component`展示的是以前一个`Component`的值为`Key`的字典, 这样, 我们就能获取到了.

**2.  PickerViewDataSource选中刷新**

```Swift
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
```

首先, 进行判断, 如果只有`mainContent`的情况下, 就只需要保存一下选中的位置即可,  如果`subContents` 存在, 则需要进行循环设置值(这里的逻辑和上方取值是类似的).

**3. 动画**

```Swift
    fileprivate func initAnimation() {
        /** 出现动画 */
        // 缩放动画
        let sizeShowAnimation = CAKeyframeAnimation.init(keyPath: "position.y")
        sizeShowAnimation.values = [self.bounds.height + self.desView!.bounds.height, self.bounds.height, self.bounds.height - (pickerHeight + buttonSize + 10.0)]
        
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
```

动画这里我只是简单写了一下, 这一部分比较好修改, 使用的`Group`组合了平移和透明度变换的动画, 这里我设置了代理, 主要是为了在结束的时候将`View`从控件中去除.

**4. 初始化**

```Swift
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
        // 初始化Container
        self.initContainer()
        // 初始化控件
        self.initViews()
```
在这里, 就已经将控件初始化出来, 添加是在`show()`的时候, 才会将当前的控件添加到`keywindow`中去, 在`dismiss()`动画结束的时候从`keywindow` 中去除.

**5. 调用**

```Swift
        if self.picker != nil && self.view.subviews.contains(self.picker) {
            return
        }
        // mainContent: self.provinces, subContents: [self.cities, self.areas], isGroup: true
        self.picker = MXSelectableView.init(mainContent: provinces, subContents: [cities, areas], isGroup: true, selectedCallBack: { (result : [String]) in
            print(result)
        })
  
        picker.show()
```

只需要设置相关的属性, 就可以得到对应的`pickerView`, 然后调用`show()/dismiss()`用于展示和隐藏.

详细代码在: [Github]()

#### 总结

以后写代码的时候也应该多考虑一下, 当前做的东西是否可以作为可复用的模块, 尝试将组件化思维运用起来, 并去尝试使用中间者模式进行组件之间的管理, 这样可以最大程度的提高自己的效率以及减少维护代价.
