#!/usr/bin/env node

// AWS SDK を使用した Bedrock 画像生成サンプル

import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import fs from 'fs/promises';
import path from 'path';

// 設定
const CONFIG = {
  region: "us-east-1",
  outputDir: "./output"
};

// Bedrock クライアントの初期化
const client = new BedrockRuntimeClient({
  region: CONFIG.region
});

/**
 * メイン処理
 */
async function main() {
  // サンプルプロンプト
  const prompts = [
    {
      text: "A serene Japanese garden with koi pond, cherry blossoms, and traditional bridge, highly detailed, 8k",
      negativePrompt: "low quality, blurry, distorted",
      model: "sdxl"
    },
    {
      text: "Futuristic Tokyo cityscape at night with neon lights and flying cars, cyberpunk style",
      model: "titan"
    }
  ];

  for (const [index, promptConfig] of prompts.entries()) {
    console.log(`\n=== 画像生成 ${index + 1} ===`);

    try {
      let result;
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

      if (promptConfig.model === "titan") {
        // TITAN で生成
        result = await generateImageWithTitan(promptConfig.text, {
          cfgScale: 8.0,
          samples: 1
        });

        // TITAN のレスポンス処理
        if (result.images) {
          for (let i = 0; i < result.images.length; i++) {
            const filename = `titan_${timestamp}_${i}.png`;
            await saveImage(result.images[i], filename);
          }
        }
      } else {
        // Stable Diffusion XL で生成
        result = await generateImageWithSDXL(promptConfig.text, {
          negativePrompt: promptConfig.negativePrompt,
          cfgScale: 7,
          steps: 50
        });

        // SDXL のレスポンス処理
        if (result.artifacts) {
          for (let i = 0; i < result.artifacts.length; i++) {
            const filename = `sdxl_${timestamp}_${i}.png`;
            await saveImage(result.artifacts[i].base64, filename);
          }
        }
      }

    } catch (error) {
      console.error(`❌ 画像生成に失敗しました:`, error.message);
    }
  }

  console.log("\n🎉 すべての画像生成が完了しました！");
}

/**
 * Stable Diffusion XL で画像を生成
 */
async function generateImageWithSDXL(prompt, options = {}) {
  const requestBody = {
    text_prompts: [
      {
        text: prompt,
        weight: 1.0
      }
    ],
    cfg_scale: options.cfgScale || 7,
    steps: options.steps || 50,
    seed: options.seed || Math.floor(Math.random() * 1000000),
    width: options.width || 1024,
    height: options.height || 1024,
    samples: options.samples || 1
  };

  // ネガティブプロンプトがある場合は追加
  if (options.negativePrompt) {
    requestBody.text_prompts.push({
      text: options.negativePrompt,
      weight: -1.0
    });
  }

  const command = new InvokeModelCommand({
    modelId: "stability.stable-diffusion-xl-v1",
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(requestBody)
  });

  try {
    console.log(`🎨 画像生成中...`);
    console.log(`📝 プロンプト: ${prompt}`);
    console.log(`🤖 モデル: "stability.stable-diffusion-xl-v1"`);

    const response = await client.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));

    return responseBody;
  } catch (error) {
    console.error("❌ エラーが発生しました:", error);
    throw error;
  }
}

/**
 * TITAN Image Generator で画像を生成
 */
async function generateImageWithTitan(prompt, options = {}) {
  const requestBody = {
    taskType: "TEXT_IMAGE",
    textToImageParams: {
      text: prompt
    },
    imageGenerationConfig: {
      numberOfImages: options.samples || 1,
      height: options.height || 1024,
      width: options.width || 1024,
      cfgScale: options.cfgScale || 8.0,
      seed: options.seed || Math.floor(Math.random() * 1000000)
    }
  };

  const command = new InvokeModelCommand({
    modelId: "amazon.titan-image-generator-v1",
    contentType: "application/json",
    accept: "application/json",
    body: JSON.stringify(requestBody)
  });

  try {
    console.log(`🎨 画像生成中...`);
    console.log(`📝 プロンプト: ${prompt}`);
    console.log(`🤖 モデル: amazon.titan-image-generator-v1`);

    const response = await client.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));

    return responseBody;
  } catch (error) {
    console.error("❌ エラーが発生しました:", error);
    throw error;
  }
}

/**
 * 生成された画像を保存
 */
async function saveImage(base64Data, filename) {
  // 出力ディレクトリを作成
  await fs.mkdir(CONFIG.outputDir, { recursive: true });

  // Base64 デコードして保存
  const buffer = Buffer.from(base64Data, 'base64');
  const filepath = path.join(CONFIG.outputDir, filename);

  await fs.writeFile(filepath, buffer);
  console.log(`✅ 画像を保存しました: ${filepath}`);

  return filepath;
}

// エラーハンドリング付きで実行
main().catch(error => {
  console.error("Fatal error:", error);
  process.exit(1);
});
