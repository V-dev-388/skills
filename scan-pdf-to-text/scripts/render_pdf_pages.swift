// render_pdf_pages.swift - 把扫描版 PDF 每页渲染为 JPG，供多模态识别
// 用法: swiftc -O render_pdf_pages.swift -o render_pdf_pages && ./render_pdf_pages <input.pdf> <outdir> [scale] [quality]
//   scale  默认 2.0（约 2000px 宽），中文印刷体足够清晰；可调 2.5-3.0 提清晰度
//   quality 默认 0.9（0.0-1.0），文字识别建议 >=0.85
// 输出: <outdir>/page_01.jpg, page_02.jpg, ...（JPG 体积约为 PNG 的 1/10，识别读取更快）
import PDFKit
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: render_pdf_pages <pdf> <outdir> [scale] [quality]")
    exit(1)
}
let pdfPath = args[1]
let outDir = args[2]
let scale: CGFloat = args.count >= 4 ? CGFloat(Double(args[3]) ?? 2.0) : 2.0
let quality: Double = args.count >= 5 ? Double(args[4]) ?? 0.9 : 0.9

guard let doc = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
    print("ERROR: cannot open pdf")
    exit(1)
}
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for i in 0..<doc.pageCount {
    guard let page = doc.page(at: i) else { continue }
    let bounds = page.bounds(for: .mediaBox)
    let w = Int(bounds.width * scale)
    let h = Int(bounds.height * scale)
    let img = NSImage(size: NSSize(width: w, height: h))
    img.lockFocus()
    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: w, height: h).fill()
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.saveGState()
    ctx.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: ctx)
    ctx.restoreGState()
    img.unlockFocus()

    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let jpg = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
        print("render failed page \(i+1)")
        continue
    }
    let out = "\(outDir)/page_\(String(format: "%02d", i+1)).jpg"
    try? jpg.write(to: URL(fileURLWithPath: out))
    print("saved \(out) \(w)x\(h)")
}
