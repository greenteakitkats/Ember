import SwiftUI

/// Avatar wrapped in the relationship "battery": a ring that's full
/// right after you connect and drains toward the cadence deadline.
/// Overdue people keep a small ember rather than an empty void.
struct AvatarView: View {
    let person: Person
    var size: CGFloat = 44

    private var ringWidth: CGFloat { max(2.5, size * 0.065) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, lineWidth: ringWidth)
            Circle()
                .trim(from: 0, to: person.ringFraction)
                .stroke(
                    person.healthState.color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            core
                .frame(width: size - ringWidth * 2 - 3, height: size - ringWidth * 2 - 3)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.6), value: person.ringFraction)
    }

    @ViewBuilder
    private var core: some View {
        if let data = person.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            let colors = Theme.avatarColors(for: person.name)
            ZStack {
                Circle().fill(colors.fill)
                Text(person.initials)
                    .font(.system(size: size * 0.3, weight: .semibold, design: .rounded))
                    .foregroundStyle(colors.text)
            }
        }
    }
}
