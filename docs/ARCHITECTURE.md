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
