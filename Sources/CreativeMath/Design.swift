import SwiftUI

enum Design {
    static let canvas = Color(red: 8/255, green: 9/255, blue: 11/255)
    static let surface = Color(red: 20/255, green: 22/255, blue: 26/255)
    static let elevated = Color(red: 28/255, green: 31/255, blue: 36/255)
    static let border = Color(red: 41/255, green: 45/255, blue: 52/255)
    static let primary = Color(red: 232/255, green: 234/255, blue: 237/255)
    static let secondary = Color(red: 170/255, green: 177/255, blue: 188/255)
    static let accent = Color(red: 145/255, green: 169/255, blue: 232/255)
    static let error = Color(red: 239/255, green: 142/255, blue: 142/255)
    static let title = Font.system(size: 20)
    static let section = Font.system(size: 13, weight: .semibold)
    static let body = Font.system(size: 13)
    static let metadata = Font.system(size: 11)
    static let numeric = Font.system(size: 12, design: .monospaced)
}
