import SwiftUI

/// The warm visual system, shared by the app and the widget: cream
/// canvas, warm card surfaces, and a small quilt of avatar hues so the
/// network doesn't render as a uniform wall of one tint. Dark mode is
/// warm charcoal — neutral with warmth, never saturated brown.
enum Theme {
    static let canvas = Color(light: 0xFAF3EA, dark: 0x1C1917)
    static let card = Color(light: 0xFFFDFA, dark: 0x292524)
    static let ringTrack = Color(light: 0xF0E2D4, dark: 0x44403C)

    private static let avatarPalette: [(fill: Color, text: Color)] = [
        (Color(light: 0xF5D8CA, dark: 0x53392C), Color(light: 0x9C4A2F, dark: 0xF0B49E)),
        (Color(light: 0xF7E6C4, dark: 0x4E4224), Color(light: 0x7C5A10, dark: 0xEBC981)),
        (Color(light: 0xF4D6DC, dark: 0x4E353D), Color(light: 0x96455B, dark: 0xEDAEBE)),
        (Color(light: 0xE3E9D2, dark: 0x3A402E), Color(light: 0x5C6B3C, dark: 0xC0CFA0)),
        (Color(light: 0xE5DCEF, dark: 0x3E374C), Color(light: 0x6D5590, dark: 0xC9B8E4)),
        (Color(light: 0xD9E7E4, dark: 0x30413D), Color(light: 0x3F6B62, dark: 0xA5CDC5)),
    ]

    /// Stable per-person hue: the same name always lands on the same
    /// palette entry, so people keep their color across launches.
    static func avatarColors(for name: String) -> (fill: Color, text: Color) {
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return avatarPalette[abs(sum) % avatarPalette.count]
    }
}
