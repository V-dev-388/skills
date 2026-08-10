# WorkBuddy Skills

WorkBuddy 用户级技能集合，全部基于 macOS 原生工具链（Swift + PDFKit + 多模态识别），无第三方依赖。

## 目录

| Skill | 说明 | 内容 |
|---|---|---|
| `scan-pdf-to-text/` | 扫描版 PDF（无文本层）→ 结构化文字 | SKILL.md + `scripts/pdf_text_layer.swift`（文本层检测）+ `scripts/render_pdf_pages.swift`（渲染 JPG）+ `scripts/crop_region.swift`（局部裁剪精识别） |
| `pdf-md-verify/` | PDF 与 MD 文字一致性核对 | SKILL.md（复用 scan-pdf-to-text 脚本，含差异局部复核流程） |

- `dist/`：各 skill 的分发 zip 包（与原目录内容一致）。
