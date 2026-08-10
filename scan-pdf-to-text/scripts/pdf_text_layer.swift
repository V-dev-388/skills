// pdf_text_layer.swift - 检测 PDF 是否有文本层；若有则输出提取的全文
// 用法: swiftc -O pdf_text_layer.swift -o pdf_text_layer && ./pdf_text_layer <input.pdf>
// 输出: 首行为 "HAS_TEXT_LAYER pages=N chars=M" 或 "NO_TEXT_LAYER pages=N"
//       有文本层时后续输出完整提取文本
import PDFKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("usage: pdf_text_layer <pdf>")
    exit(1)
}
guard let doc = PDFDocument(url: URL(fileURLWithPath: args[1])) else {
    print("ERROR: cannot open pdf")
    exit(1)
}
let full = doc.string ?? ""
let trimmed = full.trimmingCharacters(in: .whitespacesAndNewlines)
if trimmed.isEmpty {
    print("NO_TEXT_LAYER pages=\(doc.pageCount)")
} else {
    print("HAS_TEXT_LAYER pages=\(doc.pageCount) chars=\(trimmed.count)")
    print(full)
}
