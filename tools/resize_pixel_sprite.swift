import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 5,
      let width = Int(CommandLine.arguments[3]),
      let height = Int(CommandLine.arguments[4]) else {
    fputs("usage: resize_pixel_sprite input output width height\n", stderr)
    exit(2)
}
let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
context.interpolationQuality = .none
context.setBlendMode(.copy)
context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
guard let resized = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(destination, resized, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
