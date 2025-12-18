#!/usr/bin/env node

// AWS Bedrock TITAN Image Generator を使用した画像編集サンプル

import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// 設定
const CONFIG = {
  region: "us-east-1",
  modelId: "amazon.titan-image-generator-v1",
  outputDir: "./output",
  samplesDir: "./samples"
};

// Bedrock クライアントの初期化
const client = new BedrockRuntimeClient({ 
  region: CONFIG.region 
});

/**
 * 画像をBase64エンコード
 */
async function encodeImage(imagePath) {
  const imageBuffer = await fs.readFile(imagePath);
  return imageBuffer.toString('base64');
}

/**
 * Base64デコードして画像を保存
 */
async function saveImage(base64Data, filename) {
  await fs.mkdir(CONFIG.outputDir, { recursive: true });
  const buffer = Buffer.from(base64Data, 'base64');
  const filepath = path.join(CONFIG.outputDir, filename);
  await fs.writeFile(filepath, buffer);
  console.log(`✅ 画像を保存: ${filepath}`);
  return filepath;
}

/**
 * インペインティング（画像の一部を修正）
 * マスク画像で指定した部分だけを再生成
 */
async function inpainting(imagePath, maskPath, prompt) {
  console.log("\n🎨 インペインティング（画像の一部を修正）");
  console.log(`📝 プロンプト: ${prompt}`);
  
  const imageBase64 = await encodeImage(imagePath);
  const maskBase64 = await encodeImage(maskPath);
  
  const requestBody = {
    taskType: "INPAINTING",
    inPaintingParams: {
      text: prompt,
      image: imageBase64,
      maskImage: maskBase64
    },
    imageGenerationConfig: {
      numberOfImages: 1,
      height: 512,
      width: 512,
      cfgScale: 8.0
    }
  };
  
  const command = new InvokeModelCommand({
    modelId: CONFIG.modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(requestBody)
  });
  
  const response = await client.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));
  
  if (responseBody.images) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    for (let i = 0; i < responseBody.images.length; i++) {
      await saveImage(responseBody.images[i], `inpainting_${timestamp}_${i}.png`);
    }
  }
}

/**
 * アウトペインティング（画像を拡張）
 * マスクで指定した領域を新たに生成して拡張
 */
async function outpainting(imagePath, maskPath, prompt) {
  console.log("\n🖼️ アウトペインティング（画像を拡張）");
  console.log(`📝 プロンプト: ${prompt}`);
  
  const imageBase64 = await encodeImage(imagePath);
  const maskBase64 = await encodeImage(maskPath);
  
  const requestBody = {
    taskType: "OUTPAINTING",
    outPaintingParams: {
      text: prompt,
      image: imageBase64,
      maskImage: maskBase64
    },
    imageGenerationConfig: {
      numberOfImages: 1,
      height: 512,  // 元画像と同じサイズ
      width: 512,   // 元画像と同じサイズ
      cfgScale: 8.0
    }
  };
  
  const command = new InvokeModelCommand({
    modelId: CONFIG.modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(requestBody)
  });
  
  const response = await client.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));
  
  if (responseBody.images) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    for (let i = 0; i < responseBody.images.length; i++) {
      await saveImage(responseBody.images[i], `outpainting_${timestamp}_${i}.png`);
    }
  }
}

/**
 * 画像のバリエーション生成
 * 元画像に似た新しい画像を生成
 */
async function imageVariation(imagePath, prompt) {
  console.log("\n🔄 画像のバリエーション生成");
  console.log(`📝 プロンプト: ${prompt}`);
  
  const imageBase64 = await encodeImage(imagePath);
  
  const requestBody = {
    taskType: "IMAGE_VARIATION",
    imageVariationParams: {
      text: prompt,
      images: [imageBase64]
    },
    imageGenerationConfig: {
      numberOfImages: 3,  // 3つのバリエーションを生成
      height: 512,
      width: 512,
      cfgScale: 8.0
    }
  };
  
  const command = new InvokeModelCommand({
    modelId: CONFIG.modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(requestBody)
  });
  
  const response = await client.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));
  
  if (responseBody.images) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    for (let i = 0; i < responseBody.images.length; i++) {
      await saveImage(responseBody.images[i], `variation_${timestamp}_${i}.png`);
    }
  }
}

/**
 * 背景削除
 * オブジェクトの背景を透明にする
 */
async function removeBackground(imagePath) {
  console.log("\n✂️ 背景削除");
  
  const imageBase64 = await encodeImage(imagePath);
  
  const requestBody = {
    taskType: "BACKGROUND_REMOVAL",
    backgroundRemovalParams: {
      image: imageBase64
    }
  };
  
  const command = new InvokeModelCommand({
    modelId: CONFIG.modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(requestBody)
  });
  
  try {
    const response = await client.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    
    if (responseBody.images) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      for (let i = 0; i < responseBody.images.length; i++) {
        await saveImage(responseBody.images[i], `no_background_${timestamp}_${i}.png`);
      }
    }
  } catch (error) {
    console.log("⚠️ 背景削除は現在のモデルではサポートされていない可能性があります");
    console.error(error.message);
  }
}

/**
 * カラーガイド付き画像生成
 * 色の配置を指定して画像を生成
 */
async function colorGuidedGeneration(colorMapPath, prompt) {
  console.log("\n🎨 カラーガイド付き画像生成");
  console.log(`📝 プロンプト: ${prompt}`);
  
  const colorMapBase64 = await encodeImage(colorMapPath);
  
  const requestBody = {
    taskType: "COLOR_GUIDED_GENERATION",
    colorGuidedGenerationParams: {
      text: prompt,
      referenceImage: colorMapBase64,
      colors: ["#FF0000", "#00FF00", "#0000FF"]  // RGB カラーパレット
    },
    imageGenerationConfig: {
      numberOfImages: 1,
      height: 512,
      width: 512,
      cfgScale: 8.0
    }
  };
  
  const command = new InvokeModelCommand({
    modelId: CONFIG.modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(requestBody)
  });
  
  try {
    const response = await client.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    
    if (responseBody.images) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      for (let i = 0; i < responseBody.images.length; i++) {
        await saveImage(responseBody.images[i], `color_guided_${timestamp}_${i}.png`);
      }
    }
  } catch (error) {
    console.log("⚠️ カラーガイド生成は現在のモデルではサポートされていない可能性があります");
    console.error(error.message);
  }
}

/**
 * サンプル画像とマスクを生成
 */
async function createSampleImages() {
  console.log("\n📁 サンプル画像を準備中...");
  
  await fs.mkdir(CONFIG.samplesDir, { recursive: true });
  
  // サンプル画像を生成（単色の正方形）
  const { createCanvas } = await import('canvas').catch(() => {
    console.log("⚠️ canvas パッケージがインストールされていません");
    console.log("サンプル画像生成をスキップします");
    console.log("実際の画像を samples/ フォルダに配置してください");
    return { createCanvas: null };
  });
  
  if (!createCanvas) return false;
  
  // 512x512 のサンプル画像
  const canvas = createCanvas(512, 512);
  const ctx = canvas.getContext('2d');
  
  // アンチエイリアスを無効化（重要！）
  ctx.imageSmoothingEnabled = false;
  
  // グラデーション背景のサンプル画像
  const gradient = ctx.createLinearGradient(0, 0, 512, 512);
  gradient.addColorStop(0, '#FF6B6B');
  gradient.addColorStop(0.5, '#4ECDC4');
  gradient.addColorStop(1, '#45B7D1');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 512, 512);
  
  // 中央に四角形を描画（アンチエイリアスを避けるため円ではなく四角形）
  ctx.fillStyle = '#FFFFFF';
  ctx.fillRect(206, 206, 100, 100);
  
  const sampleImageBuffer = canvas.toBuffer('image/png');
  await fs.writeFile(path.join(CONFIG.samplesDir, 'sample.png'), sampleImageBuffer);
  
  // インペインティング用マスク（中央の円部分）
  // アンチエイリアスを無効化
  ctx.imageSmoothingEnabled = false;
  ctx.clearRect(0, 0, 512, 512);
  ctx.fillStyle = '#FFFFFF';
  ctx.fillRect(0, 0, 512, 512);
  ctx.fillStyle = '#000000';
  // 四角形で作成（アンチエイリアスを避けるため）
  ctx.fillRect(206, 206, 100, 100);
  
  const maskBuffer = canvas.toBuffer('image/png');
  await fs.writeFile(path.join(CONFIG.samplesDir, 'mask_center.png'), maskBuffer);
  
  // アウトペインティング用マスク（周辺部分）
  const outCanvas = createCanvas(1280, 720);
  const outCtx = outCanvas.getContext('2d');
  outCtx.imageSmoothingEnabled = false;  // アンチエイリアス無効化
  outCtx.fillStyle = '#000000';
  outCtx.fillRect(0, 0, 1280, 720);
  outCtx.fillStyle = '#FFFFFF';
  outCtx.fillRect(384, 104, 512, 512);  // 中央に元画像サイズの白い領域
  
  const outMaskBuffer = outCanvas.toBuffer('image/png');
  await fs.writeFile(path.join(CONFIG.samplesDir, 'mask_outpaint.png'), outMaskBuffer);
  
  console.log("✅ サンプル画像を生成しました");
  return true;
}

/**
 * メイン処理
 */
async function main() {
  console.log("🚀 Bedrock Image Editor - 画像編集デモ");
  console.log("=" .repeat(50));
  
  // サンプル画像の準備
  const hasSamples = await createSampleImages();
  
  if (!hasSamples) {
    console.log("\n⚠️ 実際の画像ファイルを使用する場合:");
    console.log("1. samples/ フォルダを作成");
    console.log("2. sample.png (512x512) を配置");
    console.log("3. mask_center.png (編集したい部分が黒のマスク画像) を配置");
    console.log("4. mask_outpaint.png (拡張用のマスク画像) を配置");
    return;
  }
  
  const sampleImage = path.join(CONFIG.samplesDir, 'sample.png');
  const maskCenter = path.join(CONFIG.samplesDir, 'mask_center.png');
  const maskOutpaint = path.join(CONFIG.samplesDir, 'mask_outpaint.png');
  
  try {
    // 1. インペインティング（画像の一部を変更）
    await inpainting(
      sampleImage,
      maskCenter,
      "beautiful golden star with cosmic energy"
    );
    
    // 2. バリエーション生成
    await imageVariation(
      sampleImage,
      "abstract art with vibrant colors"
    );
    
    // 3. アウトペインティング（画像を拡張）- 同じサイズのマスクを使用
    const sampleImageFor512 = path.join(CONFIG.samplesDir, 'sample.png');
    const maskFor512 = path.join(CONFIG.samplesDir, 'mask_outpaint_512.png');
    
    // 512x512 のアウトペインティング用マスクを作成
    const outCanvas512 = createCanvas(512, 512);
    const outCtx512 = outCanvas512.getContext('2d');
    outCtx512.imageSmoothingEnabled = false;
    
    // 外側を黒（拡張する部分）、中央の小さい領域を白（元画像部分）
    outCtx512.fillStyle = '#000000';
    outCtx512.fillRect(0, 0, 512, 512);
    outCtx512.fillStyle = '#FFFFFF';
    outCtx512.fillRect(156, 156, 200, 200);  // 中央に200x200の白い領域
    
    const outMask512Buffer = outCanvas512.toBuffer('image/png');
    await fs.writeFile(maskFor512, outMask512Buffer);
    
    await outpainting(
      sampleImageFor512,
      maskFor512,
      "extend with beautiful landscape and mountains"
    );
    
    // 4. 背景削除（サポートされている場合）
    await removeBackground(sampleImage);
    
    // 5. カラーガイド生成（サポートされている場合）
    await colorGuidedGeneration(
      sampleImage,
      "futuristic city with neon lights"
    );
    
  } catch (error) {
    console.error("\n❌ エラーが発生しました:", error.message);
    
    if (error.message.includes("ValidationException")) {
      console.log("\n💡 ヒント:");
      console.log("- タスクタイプがモデルでサポートされているか確認");
      console.log("- 画像サイズが適切か確認（512x512 or 1024x1024）");
      console.log("- マスク画像が正しい形式か確認");
    }
  }
  
  console.log("\n🎉 画像編集処理が完了しました！");
  console.log(`📂 生成された画像: ${CONFIG.outputDir}/`);
}

// 実行
main().catch(error => {
  console.error("Fatal error:", error);
  process.exit(1);
});