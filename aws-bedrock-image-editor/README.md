# AWS Bedrock 画像生成サンプル

AWS Bedrock を使用した画像生成のサンプルコードです。AWS CLI と Node.js SDK の両方の実装を提供しています。

## 前提条件

1. **AWS アカウント**: Bedrock が有効化されていること
2. **モデルアクセス**: AWS コンソールから使用したいモデルへのアクセスをリクエスト
   - Stable Diffusion XL (stability.stable-diffusion-xl-v1)
   - TITAN Image Generator (amazon.titan-image-generator-v1)
3. **AWS 認証情報**: AWS CLI が設定済みであること
4. **リージョン**: `us-east-1` など Bedrock が利用可能なリージョン

## モデルアクセスの有効化

1. AWS コンソールにログイン
2. Amazon Bedrock サービスに移動
3. 左メニューから「Model access」を選択
4. 使用したいモデルを選択して「Request access」をクリック
5. アクセスが承認されるまで待つ（通常は即座に承認）

## 使い方

### 方法1: AWS CLI を使用

シンプルなシェルスクリプトで画像を生成します。

```bash
# スクリプトを実行
./bedrock-cli.sh
```

スクリプト内でプロンプトを編集できます：

```bash
PROMPT="Your custom prompt here"
NEGATIVE_PROMPT="Things to avoid"
```

### 方法2: Node.js SDK を使用

より柔軟な制御が可能な Node.js 実装です。

```bash
# 依存関係をインストール
npm install

# 画像生成を実行
npm run generate
# または
node bedrock-sdk.mjs
```

## ファイル構成

```
aws-bedrock/
├── bedrock-cli.sh       # AWS CLI を使用したシンプルな実装
├── bedrock-sdk.mjs      # Node.js SDK を使用した実装
├── package.json         # Node.js プロジェクト設定
├── plan.md             # システム構成計画（参考用）
├── README.md           # このファイル
└── output/             # 生成された画像の保存先（自動作成）
```

## カスタマイズ

### プロンプトの変更

`bedrock-sdk.mjs` の `prompts` 配列を編集：

```javascript
const prompts = [
  {
    text: "あなたのプロンプト",
    negativePrompt: "避けたい要素",
    model: "sdxl"  // または "titan"
  }
];
```

### パラメータの調整

画像生成パラメータをカスタマイズ：

```javascript
// Stable Diffusion XL
{
  cfgScale: 7,      // 1-20: プロンプトへの忠実度
  steps: 50,        // 10-150: 生成ステップ数
  width: 1024,      // 画像の幅
  height: 1024,     // 画像の高さ
  seed: 42          // シード値（再現性のため）
}

// TITAN Image Generator
{
  cfgScale: 8.0,    // 1.1-10.0: プロンプトへの忠実度
  numberOfImages: 1, // 生成する画像数
  seed: 12345       // シード値
}
```

## 利用可能なモデル

### 1. Stable Diffusion XL (SDXL)
- **モデル ID**: `stability.stable-diffusion-xl-v1`
- **特徴**: 高品質、詳細な画像生成
- **解像度**: 最大 1024x1024
- **ネガティブプロンプト**: サポート

### 2. TITAN Image Generator
- **モデル ID**: `amazon.titan-image-generator-v1`
- **特徴**: AWS 純正、安定した生成
- **解像度**: 最大 1024x1024
- **追加機能**: インペインティング、アウトペインティング

### 3. Stable Diffusion 3 (最新)
- **モデル ID**: `stability.stable-diffusion-3-*`
- **特徴**: 最新モデル、より高度な理解力
- **注意**: 利用可能性はリージョンによる

## コスト

料金は生成する画像のサイズと枚数によって異なります：

- **SDXL**:
  - 512x512 以下: $0.018/画像
  - 1024x1024: $0.036/画像

- **TITAN**:
  - 512x512: $0.008/画像
  - 1024x1024: $0.012/画像

詳細は [AWS Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/) を参照してください。

## トラブルシューティング

### よくあるエラー

1. **AccessDeniedException**
   - 原因: モデルへのアクセスが許可されていない
   - 解決: AWS コンソールでモデルアクセスをリクエスト

2. **ResourceNotFoundException**
   - 原因: 指定したモデルが利用できない
   - 解決: リージョンとモデル ID を確認

3. **ValidationException**
   - 原因: パラメータが不正
   - 解決: パラメータの範囲と型を確認

4. **ThrottlingException**
   - 原因: API リクエスト制限
   - 解決: リトライロジックを実装、またはレート制限を調整

### デバッグ

AWS CLI でのデバッグ：
```bash
aws bedrock-runtime invoke-model \
  --debug \
  --region us-east-1 \
  --model-id stability.stable-diffusion-xl-v1 \
  --body '{"text_prompts":[{"text":"test"}]}' \
  response.json
```

## 次のステップ

本格的なシステムを構築する場合は、`plan.md` を参照してください：

1. **パターン1**: API Gateway + Lambda 構成（シンプル）
2. **パターン2**: SQS + 非同期処理（スケーラブル）
3. **パターン3**: Web UI 統合（ユーザーフレンドリー）
4. **パターン4**: バッチ処理（定期実行）

## 画像編集機能

AWS Bedrock の TITAN Image Generator は画像生成だけでなく、既存画像の編集も可能です。

### 画像編集の実行方法

```bash
# シンプル版（外部パッケージ不要）
npm run edit

# 高機能版（canvas パッケージが必要）
npm install canvas  # 初回のみ
npm run edit-advanced
```

### 利用可能な編集機能

#### 1. インペインティング (Inpainting)
画像の一部を修正・置き換える機能です。

- **用途**: オブジェクトの削除、置き換え、修正
- **必要なもの**:
  - 元画像 (original.png)
  - マスク画像 (mask.png) - 編集したい部分を黒、残す部分を白
  - プロンプト - 新しく生成したい内容

```javascript
// 使用例
{
  taskType: "INPAINTING",
  inPaintingParams: {
    text: "beautiful flowers",  // 黒い部分に生成する内容
    image: originalImageBase64,
    maskImage: maskImageBase64
  }
}
```

#### 2. アウトペインティング (Outpainting)
画像を外側に拡張する機能です。

- **用途**: 画像の拡大、背景の追加
- **必要なもの**:
  - 元画像
  - 拡張用マスク（元画像部分が白、拡張部分が黒）
  - プロンプト

```javascript
// 使用例
{
  taskType: "OUTPAINTING",
  outPaintingParams: {
    text: "extend with landscape",
    image: originalImageBase64,
    maskImage: outpaintMaskBase64
  }
}
```

#### 3. 画像バリエーション (Image Variation)
元画像に似た新しい画像を生成します。

- **用途**: スタイルを保ちつつ異なるバージョンを作成
- **必要なもの**: 元画像とプロンプト

```javascript
// 使用例
{
  taskType: "IMAGE_VARIATION",
  imageVariationParams: {
    text: "sunset version",
    images: [originalImageBase64]
  }
}
```

#### 4. 背景削除 (Background Removal)
※ モデルによってはサポートされていない場合があります

- **用途**: オブジェクトの切り抜き
- **必要なもの**: 元画像のみ

### サンプルファイルの準備

インペインティングを試す場合：

1. `samples/` フォルダを作成
2. `samples/original.png` - 編集したい画像（512x512 推奨）
3. `samples/mask.png` - マスク画像（同サイズ）
   - 編集したい部分: 黒 (RGB: 0,0,0)
   - 残す部分: 白 (RGB: 255,255,255)

### マスク画像の作成方法

#### 方法1: 画像編集ソフトを使用
- GIMP、Photoshop などで作成
- レイヤーを使って黒と白で塗り分け

#### 方法2: オンラインツール
- [Photopea](https://www.photopea.com/) - 無料のオンライン画像エディタ
- ブラシツールで黒く塗るだけ

#### 方法3: プログラムで生成（canvas 使用）
```javascript
const canvas = createCanvas(512, 512);
const ctx = canvas.getContext('2d');

// 全体を白で塗る
ctx.fillStyle = '#FFFFFF';
ctx.fillRect(0, 0, 512, 512);

// 編集したい部分を黒で塗る
ctx.fillStyle = '#000000';
ctx.beginPath();
ctx.arc(256, 256, 100, 0, Math.PI * 2);  // 中央に円
ctx.fill();
```

### ファイル構成（画像編集追加版）

```
aws-bedrock/
├── bedrock-cli.sh           # AWS CLI 画像生成
├── bedrock-sdk.mjs          # Node.js SDK 画像生成
├── image-editor-simple.mjs  # シンプルな画像編集（外部パッケージ不要）
├── image-editor.mjs         # 高機能画像編集（canvas パッケージ使用）
├── package.json
├── README.md
├── plan.md
├── samples/                 # サンプル画像フォルダ（オプション）
│   ├── original.png        # 編集する元画像
│   ├── mask.png           # インペインティング用マスク
│   └── mask_outpaint.png  # アウトペインティング用マスク
└── output/                  # 生成・編集された画像の保存先
```

### 画像編集のベストプラクティス

1. **画像サイズ**: 512x512 または 1024x1024 を推奨
2. **マスクの精度**: エッジをきれいにすると良い結果が得られる
3. **プロンプト**: 具体的で詳細な記述が効果的
4. **cfg_scale**: 7-10 の範囲が一般的に良好
5. **複数生成**: numberOfImages を増やして選択肢を増やす

### トラブルシューティング（画像編集）

#### ValidationException
- 画像サイズが不適切（512x512 or 1024x1024 を使用）
- マスク画像と元画像のサイズが異なる
- タスクタイプがモデルでサポートされていない

#### 画質が悪い
- cfg_scale を調整（高すぎると歪む）
- より詳細なプロンプトを使用
- seed 値を変えて複数試す

#### マスクが機能しない
- 完全な黒 (0,0,0) と白 (255,255,255) を使用
- グレースケールは避ける
- PNG 形式で保存

## リソース

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Bedrock Runtime API Reference](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_Operations_Amazon_Bedrock_Runtime.html)
- [TITAN Image Generator Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-image-models.html)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/)
- [Stable Diffusion Prompting Guide](https://stability.ai/blog/stable-diffusion-prompt-guide)

