//
//  ImageButton.swift
//  macollama
//
//  Created by BillyPark on 2/3/25.
//

import SwiftUI

struct HoverImageButton: View {
    
    let imageName: String
    let size: CGFloat
    let btnColor: Color
    let action: () -> Void
    
    init(
        imageName: String = "plus",
        size: CGFloat = 18,
        btnColor: Color = .gray,
        action: @escaping () -> Void
    ) {
        self.imageName = imageName
        self.size = size
        self.btnColor = btnColor
        self.action = action
    }
    
    @State private var isHovered = false
    @State private var isTapped = false
    @State private var hoverTimer: Timer?
    
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: size + 12, height: size + 12)
                .overlay(
                    Image(systemName: imageName)
                        .font(.system(size: size))
                        .foregroundColor(isTapped ? .white : (isHovered ? .white : btnColor))
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    isTapped ? Color.gray.opacity(0.5) :
                                    (isHovered ? Color.gray.opacity(0.3) : Color.clear)
                                )
                        )
                )
                .contentShape(Rectangle())
                .onHover { hovering in
                    hoverTimer?.invalidate()
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovered = hovering
                        }
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isTapped = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isTapped = false
                        }
                        action()
                    }
                }            
        }
    }
}
