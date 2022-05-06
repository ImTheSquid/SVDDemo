//
//  ImageView.swift
//  SVDDemo
//
//  Created by Jack Hogan on 5/3/22.
//

import SwiftUI

struct ImageView: View {
    let image: NSImage
    let pixelType: ImagePixelType
    let isLoading: Bool
    
    init(imageData: Data, pixelType: ImagePixelType, isLoading: Bool) {
        self.image = NSImage(data: imageData)!
        self.pixelType = pixelType
        self.isLoading = isLoading
    }
    
    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .colorMultiply(pixelType.color)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(radius: 3, x: 0, y: 3)
                .blur(radius: isLoading ? 8 : 0)
            
            if (isLoading) {
                ProgressView()
            }
        }
        .animation(.default, value: isLoading)
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView(imageData: Data(), pixelType: .all, isLoading: false)
    }
}
