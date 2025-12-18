#!/usr/bin/env node

// シンプルな画像編集サンプル（canvas パッケージ不要版）

import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import fs from 'fs/promises';
import path from 'path';

const CONFIG = {
  region: "us-east-1",
  modelId: "amazon.titan-image-generator-v1",
  outputDir: "./output"
};

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
 * インペインティングのデモ
 */
async function demoInpainting() {
  console.log("\n=== インペインティングデモ ===");
  console.log("画像の一部を修正する機能です");
  console.log("使い方: 元画像とマスク画像（修正したい部分が黒）を用意してください");
  
  // ファイルが存在する場合のみ実行
  try {
    await fs.access('./samples/original.png');
    await fs.access('./samples/mask.png');
    
    const imageBase64 = await encodeImage('./samples/original.png');
    const maskBase64 = await encodeImage('./samples/mask.png');
    
    const requestBody = {
      taskType: "INPAINTING",
      inPaintingParams: {
        text: "beautiful flowers and butterflies",
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
      const timestamp = Date.now();
      await saveImage(responseBody.images[0], `inpainting_${timestamp}.png`);
    }
  } catch (error) {
    console.log("⚠️ samples/original.png と samples/mask.png が必要です");
    console.log("スキップします...");
  }
}

/**
 * バリエーション生成のデモ
 */
async function demoVariation() {
  console.log("\n=== バリエーション生成デモ ===");
  console.log("元画像に似た新しい画像を生成します");
  
  try {
    await fs.access('./samples/original.png');
    
    const imageBase64 = await encodeImage('./samples/original.png');
    
    const requestBody = {
      taskType: "IMAGE_VARIATION",
      imageVariationParams: {
        text: "similar style but different composition",
        images: [imageBase64]
      },
      imageGenerationConfig: {
        numberOfImages: 3,
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
      const timestamp = Date.now();
      for (let i = 0; i < responseBody.images.length; i++) {
        await saveImage(responseBody.images[i], `variation_${timestamp}_${i}.png`);
      }
    }
  } catch (error) {
    console.log("⚠️ samples/original.png が必要です");
    console.log("スキップします...");
  }
}

/**
 * テキストから画像生成して、それを編集する例
 */
async function fullDemo() {
  console.log("\n=== フルデモ: 画像生成→編集 ===");
  
  // Step 1: 画像を生成
  console.log("\n📝 Step 1: 元となる画像を生成");
  
  const generateBody = {
    taskType: "TEXT_IMAGE",
    textToImageParams: {
      text: "A simple landscape with mountains and a lake, clear blue sky"
    },
    imageGenerationConfig: {
      numberOfImages: 1,
      height: 512,
      width: 512,
      cfgScale: 8.0
    }
  };
  
  const generateCommand = new InvokeModelCommand({
    modelId: CONFIG.modelId,
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(generateBody)
  });
  
  try {
    const generateResponse = await client.send(generateCommand);
    const generateResult = JSON.parse(new TextDecoder().decode(generateResponse.body));
    
    if (generateResult.images && generateResult.images.length > 0) {
      const originalImage = generateResult.images[0];
      const timestamp = Date.now();
      
      // 生成した画像を保存
      await saveImage(originalImage, `generated_original_${timestamp}.png`);
      
      // Step 2: バリエーションを作成
      console.log("\n🔄 Step 2: バリエーションを生成");
      
      const variationBody = {
        taskType: "IMAGE_VARIATION",
        imageVariationParams: {
          text: "sunset version with warm colors and dramatic clouds",
          images: [originalImage]
        },
        imageGenerationConfig: {
          numberOfImages: 2,
          height: 512,
          width: 512,
          cfgScale: 8.0
        }
      };
      
      const variationCommand = new InvokeModelCommand({
        modelId: CONFIG.modelId,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify(variationBody)
      });
      
      const variationResponse = await client.send(variationCommand);
      const variationResult = JSON.parse(new TextDecoder().decode(variationResponse.body));
      
      if (variationResult.images) {
        for (let i = 0; i < variationResult.images.length; i++) {
          await saveImage(variationResult.images[i], `variation_${timestamp}_${i}.png`);
        }
      }
    }
  } catch (error) {
    console.error("❌ エラー:", error.message);
  }
}

/**
 * メイン処理
 */
async function main() {
  console.log("🎨 Bedrock 画像編集サンプル");
  console.log("=" .repeat(50));
  
  // フルデモを実行
  await fullDemo();
  
  // サンプル画像がある場合は追加デモ
  await demoInpainting();
  await demoVariation();
  
  console.log("\n🎉 完了！");
  console.log(`📂 生成された画像は ${CONFIG.outputDir}/ に保存されています`);
  
  console.log("\n💡 ヒント:");
  console.log("- インペインティングを試すには samples/original.png と samples/mask.png を用意");
  console.log("- マスク画像は編集したい部分を黒、残す部分を白にしてください");
  console.log("- アウトペインティングは画像を拡張する機能です（大きめのマスクが必要）");
}

main().catch(error => {
  console.error("Fatal error:", error);
  process.exit(1);
});