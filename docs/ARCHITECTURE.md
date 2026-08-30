# PackageHub 技术方案

## 1. 项目概述

PackageHub 是一款用于识别、整理和管理包裹信息、一站式展示身份码的移动端应用。应用以 Flutter 作为跨平台 UI 和业务逻辑层，通过 iOS 与 Android 原生能力接入系统分享入口和 OCR 能力，将图片、截图或分享内容中的包裹信息提取后保存到本地 SQLite 数据库。

## 2. 技术架构

```text
PackageHub
|
├── UI / 业务逻辑
│   └── Flutter + Dart
|
├── iOS
│   ├── Swift
│   ├── Apple Vision OCR
│   └── Share Extension
|
├── Android
│   ├── Kotlin
│   ├── ML Kit OCR
│   └── ACTION_SEND / Share
|
└── 数据
    └── 本地 SQLite
```

## 3. 分层设计

### 3.1 UI / 业务逻辑层

技术选型：Flutter + Dart

职责：

- 提供跨平台一致的用户界面。
- 承载包裹列表、详情、识别结果确认、搜索筛选等核心业务流程。
- 管理应用状态、路由、表单校验和本地数据访问。
- 通过 Method Channel 与 iOS、Android 原生模块通信。

建议模块：

- `features/packages`：包裹列表、详情、创建和编辑。
- `features/ocr_review`：OCR 识别结果确认和字段修正。
- `features/share_import`：处理从系统分享入口导入的数据。
- `data/local`：SQLite 数据访问层。
- `platform`：封装原生 OCR、分享入口和权限请求。

### 3.2 iOS 原生层

技术选型：Swift + Apple Vision OCR + Share Extension

职责：

- 使用 Share Extension 接收来自系统分享菜单的图片、截图或文本。
- 使用 Apple Vision 进行本地 OCR 识别。
- 将识别文本和图片元数据传递给 Flutter 主应用。
- 处理 iOS 沙盒、App Group 数据共享和权限相关逻辑。

关键能力：

- `VNRecognizeTextRequest`：识别图片中的文字。
- `Share Extension`：接收外部应用分享内容。
- `App Groups`：在扩展和主应用之间共享临时导入数据。
- `Method Channel`：向 Flutter 暴露 OCR 和导入结果。

### 3.3 Android 原生层

技术选型：Kotlin + ML Kit OCR + ACTION_SEND / Share

职责：

- 通过 `ACTION_SEND` / `ACTION_SEND_MULTIPLE` 接收系统分享内容。
- 使用 Google ML Kit Text Recognition 进行本地 OCR。
- 将识别结果传递给 Flutter 层进行展示和确认。
- 处理 Android 文件 URI、运行时权限和生命周期差异。

关键能力：

- `TextRecognition.getClient(...)`：识别图片文字。
- `Intent.ACTION_SEND`：接收图片或文本分享。
- `ContentResolver`：读取分享来源提供的文件内容。
- `Method Channel`：对 Flutter 提供平台能力。

### 3.4 数据层

技术选型：本地 SQLite

职责：

- 保存包裹记录、OCR 原始文本、识别字段、图片引用和状态变化。
- 支持离线访问和本地搜索。
- 为后续同步能力预留字段，例如远端 ID、更新时间和同步状态。

建议核心表：

```sql
CREATE TABLE packages (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  tracking_no TEXT,
  carrier TEXT,
  status TEXT NOT NULL,
  source TEXT NOT NULL,
  raw_text TEXT,
  image_path TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE package_events (
  id TEXT PRIMARY KEY,
  package_id TEXT NOT NULL,
  event_time INTEGER,
  location TEXT,
  description TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (package_id) REFERENCES packages(id)
);
```

## 4. 核心流程

### 4.1 分享导入流程

1. 用户在系统相册、截图、快递 App 或其他应用中选择分享。
2. iOS Share Extension 或 Android Share Intent 接收内容。
3. 原生层读取图片或文本，并执行 OCR。
4. 原生层将 OCR 结果传递给 Flutter。
5. Flutter 展示识别结果确认页。
6. 用户确认或修正后保存到 SQLite。

### 4.2 应用内 OCR 流程

1. 用户在 PackageHub 内选择图片或拍照。
2. Flutter 请求原生 OCR 能力。
3. iOS 使用 Apple Vision，Android 使用 ML Kit。
4. Flutter 对识别文本进行字段解析。
5. 用户确认后生成包裹记录。

### 4.3 包裹管理流程

1. 首页展示本地包裹列表。
2. 用户可按状态、承运商、关键词筛选。
3. 用户进入详情页查看识别文本、物流单号和事件记录。
4. 用户可手动编辑识别错误字段。

## 5. 平台通信方案

Flutter 与原生层通过 Method Channel 通信。

建议 Channel：

- `packagehub/ocr`：执行 OCR 识别。
- `packagehub/share_import`：获取分享导入内容。
- `packagehub/permissions`：处理平台权限请求。

示例接口：

```dart
abstract class PlatformOcrService {
  Future<OcrResult> recognizeImage(String imagePath);
}

abstract class ShareImportService {
  Future<SharedPayload?> getPendingSharedPayload();
}
```

## 6. OCR 结果解析

OCR 只负责提取文本，业务字段解析放在 Flutter 层统一处理，减少平台差异。

解析目标：

- 快递单号 / 运单号
- 承运商
- 包裹名称
- 物流状态
- 时间、地点和事件描述

解析策略：

- 使用正则匹配常见单号格式。
- 维护承运商关键词字典。
- 保留 OCR 原始文本，便于用户修正和后续算法优化。
- 将解析结果作为建议值展示，最终以用户确认结果为准。

## 7. 本地优先与隐私

- OCR 优先在本地设备执行。
- 包裹数据默认仅保存在本地 SQLite。
- 图片路径仅保存本地引用，不上传远端服务。
- 后续如加入云同步，应提供明确的用户授权和同步开关。

## 8. 风险与应对

| 风险 | 影响 | 应对 |
| --- | --- | --- |
| OCR 识别准确率受图片质量影响 | 字段解析错误 | 增加确认页，保留原文，支持手动修正 |
| iOS Share Extension 与主 App 数据隔离 | 分享内容无法稳定传递 | 使用 App Groups 共享临时数据 |
| Android 分享来源 URI 差异 | 文件读取失败 | 统一通过 ContentResolver 处理 |
| 平台 OCR API 差异 | 业务逻辑分叉 | OCR 只返回文本，字段解析放 Flutter |
| SQLite Schema 演进 | 版本升级风险 | 引入数据库迁移机制 |

## 9. 里程碑建议

### M1：基础应用与本地数据

- 创建 Flutter 项目结构。
- 完成包裹列表、详情、创建和编辑页面。
- 接入 SQLite。
- 支持手动新增包裹。

### M2：应用内 OCR

- iOS 接入 Apple Vision OCR。
- Android 接入 ML Kit OCR。
- Flutter 接入统一 OCR Service。
- 完成识别结果确认页。

### M3：系统分享导入

- iOS 完成 Share Extension。
- Android 完成 ACTION_SEND 接收。
- 打通分享内容到 Flutter 的导入流程。
- 支持从图片或文本创建包裹。

### M4：体验完善

- 增加搜索、筛选和状态管理。
- 优化 OCR 字段解析。
- 增加数据库迁移和错误恢复。
- 完成关键流程测试。

## 10. 后续扩展

- 云同步与多设备登录。
- 物流接口查询与状态自动更新。
- 条形码 / 二维码扫描。
- 智能承运商识别。
- 桌面端或 Web 管理后台。
