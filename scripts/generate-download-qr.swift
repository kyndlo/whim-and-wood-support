import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Vision

let destination = URL(fileURLWithPath: CommandLine.arguments[1])
let pageURL = "https://kyndlo.github.io/whim-and-wood-support/download/"
let filter = CIFilter.qrCodeGenerator()
filter.message = Data(pageURL.utf8)
filter.correctionLevel = "H"

guard let modules = filter.outputImage else {
    fatalError("Could not generate the QR code")
}

let scale: CGFloat = 10
let quietZone = scale * 4
let scaled = modules.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
let translated = scaled.transformed(by: CGAffineTransform(translationX: quietZone, y: quietZone))
let canvas = CGRect(
    x: 0,
    y: 0,
    width: scaled.extent.width + quietZone * 2,
    height: scaled.extent.height + quietZone * 2
)
let background = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: canvas)
let image = translated.composited(over: background)

let context = CIContext()
guard let cgImage = context.createCGImage(image, from: canvas) else {
    fatalError("Could not render the QR code")
}

let request = VNDetectBarcodesRequest()
try VNImageRequestHandler(cgImage: cgImage).perform([request])
guard request.results?.contains(where: { $0.payloadStringValue == pageURL }) == true else {
    fatalError("Generated QR code did not decode to the download page")
}

let bitmap = NSBitmapImageRep(cgImage: cgImage)
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the QR code as PNG")
}
try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: destination, options: .atomic)
print("Wrote verified QR code for \(pageURL) to \(destination.path)")
