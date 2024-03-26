//
//  RotationDirection.swift
//  FlipYTest
//
//  Created by Khayala Hasanli on 26.03.24.
//

import Foundation

enum RotationDirection {
    case bothNegative
    case bothPositive
    case positiveToNegative
    case negativeToPositive
    case unchanged

    static func from(currentRoll: CGFloat, previousRoll: CGFloat) -> RotationDirection {
        let isBothNegative = currentRoll < 0 && previousRoll < 0
        let isBothPositive = currentRoll > 0 && previousRoll > 0
        let isPositiveToNegative = currentRoll < 0 && previousRoll > 0
        let isNegativeToPositive = currentRoll > 0 && previousRoll < 0

        switch (isBothNegative, isBothPositive, isPositiveToNegative, isNegativeToPositive) {
            case (true, _, _, _):
                return .bothNegative
            case (_, true, _, _):
                return .bothPositive
            case (_, _, true, _):
                return .positiveToNegative
            case (_, _, _, true):
                return .negativeToPositive
            default:
                return .unchanged
        }
    }
}
