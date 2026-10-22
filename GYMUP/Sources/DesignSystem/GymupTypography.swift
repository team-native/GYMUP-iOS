import SwiftUI

enum GymupTypography {
    static let largeTitle = Font.custom("NotoSansKR-Bold", size: 32, relativeTo: .largeTitle)
    static let title = Font.custom("NotoSansKR-Bold", size: 24, relativeTo: .title)
    static let headline = Font.custom("NotoSansKR-SemiBold", size: 18, relativeTo: .headline)
    static let body = Font.custom("NotoSansKR-Regular", size: 16, relativeTo: .body)
    static let callout = Font.custom("NotoSansKR-Regular", size: 14, relativeTo: .callout)
    static let caption = Font.custom("NotoSansKR-Regular", size: 12, relativeTo: .caption)
}
