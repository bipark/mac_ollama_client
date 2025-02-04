import SwiftUI

struct CenterAlertView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.title3)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.8))
                    .shadow(radius: 10)
            )
    }
} 