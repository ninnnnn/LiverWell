//
//  ActivityManager.swift
//  LiverWell
//
//  Created by 徐若芸 on 2019/4/2.
//  Copyright © 2019 Jo Hsu. All rights reserved.
//

import Foundation
import UIKit

class ActivityManager {
    
    let trainGroup = ActivityGroup(
        titleLine1: "一點一滴訓練肌肉",
        titleLine2: "打造健康的易瘦體質",
        caption: "肌肉消耗的熱量是脂肪的十倍。活化肌肉，就算只是走路時抬頭挺胸、縮肚子也會帶來效果！",
        items: [
            TrainItem.watchTV,
            TrainItem.preventBackPain,
            TrainItem.wholeBody,
            TrainItem.upperBody,
            TrainItem.lowerBody
        ]
    )
    
    let stretchGroup = ActivityGroup(
        titleLine1: "伸展活絡身體",
        titleLine2: "提升基礎代謝三成",
        caption: "年過四十的減肥適合用緩和運動提升代謝，而不是吃力的運動減重。善用零碎時間做做伸展運動吧！",
        items: [
            StretchItem.longSit,
            StretchItem.longStand,
            StretchItem.beforeSleep
        ]
    )
    
    lazy var groups: [ActivityGroup] = [trainGroup, stretchGroup]
}


