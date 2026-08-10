// crop_region.swift - 从整页图片裁剪局部区域（可放大），用于局部精识别
// 坐标统一为"视觉坐标"（左上角原点，与 Read 工具看到的一致）：
//   像素模式: ./crop_region <img> <out> <x> <y> <w> <h> [scale]
//   比例模式: ./crop_region <img> <out> --ratio <x1> <y1> <x2> <y2> [scale]
//     --ratio 坐标 0.0-1.0，页面左上 (0,0)，右下 (1,1)
//   scale 放大倍数，默认 2.0；局部块小可调 3.0-4.0 提清晰度
// 输出: JPG（质量 0.95，局部图小无体积压力）
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 7 else {
    print("usage: crop_region <img> <out> <x> <y> <w> <h> [scale]")
    print("   or: crop_region <img> <out> --ratio <x1> <y1> <x2> <y2> [scale]")
    exit(1)
}
let inputPath = args[1]
let outPath = args[2]

guard let img = NSImage(contentsOfFile: inputPath),
      let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let cgImage = rep.cgImage else {
    print("ERROR: cannot open image")
    exit(1)
}
let imgW = rep.pixelsWide
let imgH = rep.pixelsHigh

// 解析视觉坐标（左上原点）与放大倍数
var vx: Double, vy: Double, vw: Double, vh: Double
var scale: Double
if args[3] == "--ratio" {
    guard args.count >= 8 else {
        print("usage: crop_region <img> <out> --ratio <x1> <y1> <x2> <y2> [scale]")
        exit(1)
    }
    let x1 = Double(args[4])!, y1 = Double(args[5])!
    let x2 = Double(args[6])!, y2 = Double(args[7])!
    vx = x1 * Double(imgW); vy = y1 * Double(imgH)
    vw = (x2 - x1) * Double(imgW); vh = (y2 - y1) * Double(imgH)
    scale = args.count >= 9 ? (Double(args[8]) ?? 2.0) : 2.0
} else {
    vx = Double(args[3])!; vy = Double(args[4])!
    vw = Double(args[5])!; vh = Double(args[6])!
    scale = args.count >= 8 ? (Double(args[7]) ?? 2.0) : 2.0
}
if scale <= 1.0 { scale = 2.0 }

// CGImage.cropping 用 Quartz 坐标（左下原点），从视觉坐标转换
let qx = vx
let qy = Double(imgH) - vy - vh
let rect = CGRect(x: qx, y: qy, width: vw, height: vh)

guard let croppedCG = cgImage.cropping(to: rect) else {
    print("ERROR: crop failed (region out of bounds?)")
    exit(1)
}

// 放大到目标尺寸（cropping 只裁剪不缩放）
let outW = Int(vw * scale), outH = Int(vh * scale)
let scaled = NSImage(size: NSSize(width: outW, height: outH))
scaled.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
NSGraphicsContext.current?.cgContext.draw(croppedCG, in: NSRect(x: 0, y: 0, width: outW, height: outH))
scaled.unlockFocus()

guard let tiff2 = scaled.tiffRepresentation,
      let rep2 = NSBitmapImageRep(data: tiff2),
      let out = rep2.representation(using: .jpeg, properties: [.compressionFactor: 0.95]) else {
    print("ERROR: encode failed")
    exit(1)
}
try? out.write(to: URL(fileURLWithPath: outPath))
print("saved \(outPath) \(outW)x\(outH) (crop visual \(Int(vx)),\(Int(vy)) \(Int(vw))x\(Int(vh)))")
