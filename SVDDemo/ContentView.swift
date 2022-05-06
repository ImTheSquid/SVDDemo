//
//  ContentView.swift
//  SVDDemo
//
//  Created by Jack Hogan on 5/3/22.
//

import SwiftUI
import LASwift

enum ImageViewType: String, RawRepresentable {
    case full = "Full", split = "Split"
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var imageData: Data!
    @State private var image: NSImage!
    
    @State private var redImageData: Data!
    @State private var redMatrix: Matrix!
    @State private var greenImageData: Data!
    @State private var greenMatrix: Matrix!
    @State private var blueImageData: Data!
    @State private var blueMatrix: Matrix!
    
    @State private var modes: Float = 100
    @State private var maxModes: Float = 100
    
    @State private var isCalculatingMode = false
    
    @State private var selectedView = ImageViewType.full
    
    var body: some View {
        Group {
            if image != nil {
                imageView
            } else {
                noImage
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var noImage: some View {
        VStack(spacing: 5) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(height: 70)
            
            let showLoading = imageData != nil && image == nil
            
            if (showLoading) {
                ProgressView()
            }
            
            Text(showLoading ? "Loading Image..." : "No Image Selected")
                .font(.largeTitle)
                .bold()
            
            Button("Select Image...") {
                pickImage()
            }
            .disabled(showLoading)
        }
        .padding()
    }
    
    var imageView: some View {
        GeometryReader { geometry in
            HStack(spacing: 10) {
                VStack {
                    HStack {
                        ImageView(imageData: imageData!, pixelType: .all, isLoading: isCalculatingMode)
                        if (selectedView == .split) {
                            ImageView(imageData: redImageData, pixelType: .red, isLoading: isCalculatingMode)
                        }
                    }
                    
                    if (selectedView == .split) {
                        HStack {
                            ImageView(imageData: greenImageData, pixelType: .green, isLoading: isCalculatingMode)
                            ImageView(imageData: blueImageData, pixelType: .blue, isLoading: isCalculatingMode)
                        }
                    }
                }
                .frame(width: 2 * geometry.size.width / 3)
                .animation(.default, value: selectedView)
            
                VStack {
                    Spacer()
                    
                    controls
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(colorScheme == .dark ? .black : .white)
                                .shadow(radius: 3, x: 0, y: 3)
                        )
                        .frame(width: geometry.size.width / 3)
                    
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    var controls: some View {
        VStack(spacing: 10) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 25))
            
            Button("Clear") {
                image = nil
                imageData = nil
            }
            .font(.body)
            
            Text("Dimensions: \(Int(image.size.width))x\(Int(image!.size.height))")
            
            Text("Approximate Full Size: \(Double(image.size.width * image.size.height) / 1000000.0) MB")
            
            // Size of two matrices (width x modes, height x modes) plus number of values on diagonal (modes)
            Text("Maximum Mode Size: \(Double(modes * (Float(image.size.width) + Float(image.size.height) + 1)) / 1000000.0) MB")
            
            HStack {
                Text("Modes: \(Int(modes))")
                
                Button("Apply") {
                    DispatchQueue.global(qos: .userInitiated).async {
                        isCalculatingMode = true
                        
                        blueImageData = calculateSVDImage(matrix: blueMatrix, modes: Int(modes))
                        redImageData = calculateSVDImage(matrix: redMatrix, modes: Int(modes))
                        greenImageData = calculateSVDImage(matrix: greenMatrix, modes: Int(modes))
                        
                        imageData = combine(red: redImageData, green: greenImageData, blue: blueImageData)
                        
                        isCalculatingMode = false
                    }
                }
                .font(.body)
                .disabled(isCalculatingMode)
            }
            
            Slider(value: $modes, in: 1...maxModes)
                .disabled(isCalculatingMode)
            
            Picker("Selected View:", selection: $selectedView) {
                Text(ImageViewType.full.rawValue)
                    .tag(ImageViewType.full)
                
                Text(ImageViewType.split.rawValue)
                    .tag(ImageViewType.split)
            }
            .pickerStyle(.segmented)
        }
        .font(.title)
    }
    
    func pickImage() {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select File"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.jpeg]
        openPanel.begin { (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let url = openPanel.url!
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        imageData = try Data(contentsOf: url)
                        
                        (redImageData, redMatrix) = flattenWithMatrix(imageData: imageData, pixelFilter: .red)
                        (greenImageData, greenMatrix) = flattenWithMatrix(imageData: imageData, pixelFilter: .green)
                        (blueImageData, blueMatrix) = flattenWithMatrix(imageData: imageData, pixelFilter: .blue)
                        
                        image = NSImage(data: imageData)!
                        modes = Float(min(image.size.width, image.size.height))
                        maxModes = modes
                    } catch {
                        print("Error loading image")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
