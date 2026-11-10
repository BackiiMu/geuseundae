import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 3 else { exit(2) }
let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(1) }
let width = image.width
let height = image.height
let stride = width * 4
var pixels = [UInt8](repeating: 0, count: stride * height)
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: stride, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

var background = [Bool](repeating: false, count: width * height)
var queue: [(Int, Int)] = []
for x in 0..<width { queue.append((x, 0)); queue.append((x, height - 1)) }
for y in 0..<height { queue.append((0, y)); queue.append((width - 1, y)) }
var head = 0
let tolerance = 6
while head < queue.count {
    let (x, y) = queue[head]
    head += 1
    let key = y * width + x
    if background[key] { continue }
    background[key] = true
    let offset = y * stride + x * 4
    let r = Int(pixels[offset]), g = Int(pixels[offset + 1]), b = Int(pixels[offset + 2])
    for (nx, ny) in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)] where nx >= 0 && nx < width && ny >= 0 && ny < height {
        let nkey = ny * width + nx
        if background[nkey] { continue }
        let no = ny * stride + nx * 4
        let difference = max(abs(Int(pixels[no])-r), max(abs(Int(pixels[no+1])-g), abs(Int(pixels[no+2])-b)))
        if difference <= tolerance { queue.append((nx, ny)) }
    }
}
for y in 0..<height {
    for x in 0..<width where background[y * width + x] {
        let offset = y * stride + x * 4
        pixels[offset] = 0; pixels[offset + 1] = 0; pixels[offset + 2] = 0; pixels[offset + 3] = 0
    }
}
guard let cleaned = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(destination, cleaned, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
