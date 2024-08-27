//
//  Created by Alex.M on 07.07.2022.
//

import SwiftUI

struct MessageStatusView: View {

    @Environment(\.chatTheme) private var theme

    let onRetry: () -> Void

    var body: some View {
        Group {
            theme.images.message.checkmarks
                .resizable()
                .foregroundColor(theme.colors.grayStatus)
        }
        .viewSize(MessageView.statusViewSize)
        .padding(.trailing, MessageView.horizontalStatusPadding)
    }
}
