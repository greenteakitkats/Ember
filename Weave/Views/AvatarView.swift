import SwiftUI

struct AvatarView: View {
    let person: Person
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let data = person.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color.accentColor.opacity(0.15))
                    Text(person.initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
