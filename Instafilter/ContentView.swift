//
//  ContentView.swift
//  Instafilter
//
//  Created by Juliette Rapala on 11/30/20.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var currentFilterName = "Sepia Tone"
    @State private var showingFilterSheet = false
    @State private var processedImage: UIImage?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // context is an object responsible for rendering a CIImage to a CGImage
    // They're expensive to make, so make one and keep it alive
    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)
                    
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }
                
                VStack(alignment: .leading) {
                    Text("Current Filter: \(currentFilterName)")
                }
                .padding(.top)
                
                HStack {
                    Text("Intensity")
                    // Note: This will be *very* slow on a simulator
                    Slider(value: intensity)
                }
                .padding(.vertical)

                HStack {
                    Button("Change Filter") {
                        self.showingFilterSheet = true
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        guard let processedImage = self.processedImage else { return }
                        
                        let imageSaver = ImageSaver()
                        
                        imageSaver.successHandler = {
                            self.showAlert = true
                            self.alertTitle = "Success!"
                            self.alertMessage = "Image has been saved."
                        }

                        imageSaver.errorHandler = {
                            self.showAlert = true
                            self.alertTitle = "Error"
                            self.alertMessage = "There has been a problem savings your image."
                            print("Oops: \($0.localizedDescription)")
                        }

                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) { self.setFilter(filter: CIFilter.crystallize(), name: "Crystallize") },
                    .default(Text("Edges")) { self.setFilter(filter: CIFilter.edges(), name: "Edges") },
                    .default(Text("Gaussian Blur")) { self.setFilter(filter: CIFilter.gaussianBlur(), name: "Gaussian Blur") },
                    .default(Text("Pixellate")) { self.setFilter(filter: CIFilter.pixellate(), name: "Pixellate") },
                    .default(Text("Sepia Tone")) { self.setFilter(filter: CIFilter.sepiaTone(), name: "Sepia Tone") },
                    .default(Text("Unsharp Mask")) { self.setFilter(filter: CIFilter.unsharpMask(), name: "Unsharp Mask") },
                    .default(Text("Vignette")) { self.setFilter(filter: CIFilter.vignette(), name: "Vignette") },
                    .cancel()
                ])
                
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        // set the filter intensity
        // different filters use different Core Image constants
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)}
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey)}
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)}

        // get the output image
        guard let outputImage = currentFilter.outputImage else { return }
        
        // ask CIContext to render image and place the result in image property, so it appears on screen
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(filter: CIFilter, name: String) {
        currentFilter = filter
        currentFilterName = name
        loadImage()
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
