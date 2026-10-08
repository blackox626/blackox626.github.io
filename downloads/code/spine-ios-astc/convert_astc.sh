#!/bin/bash
# Spine ASTC 纹理转换脚本
# 使用 Linear 色彩空间以匹配 Spine iOS 的 PNG 加载方式

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/Spine iOS Example/Assets/spineboy"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          Spine ASTC Texture Conversion                          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# 检查 astcenc
if ! command -v astcenc &> /dev/null; then
    echo "❌ Error: astcenc not found"
    echo "Install: brew install astc-encoder"
    echo "https://github.com/ARM-software/astc-encoder/releases"
    exit 1
fi

cd "$ASSETS_DIR"

# 转换参数
BLOCK_SIZE="${1:-8x8}"      # 默认 8x8
QUALITY="${2:--medium}"      # 默认 -medium

echo "Settings:"
echo "  Block size: $BLOCK_SIZE"
echo "  Quality: $QUALITY"
echo "  Color space: Linear (-cl)"
echo ""

for png in *.png; do
    if [ -f "$png" ]; then
        base="${png%.png}"
        astc="${base}.astc"

        echo "Converting: $png → $astc"

        # 备份如果存在
        [ -f "$astc" ] && cp "$astc" "${astc}.bak"

        # 转换 (Linear 色彩空间)
        astcenc -cl "$png" "$astc" "$BLOCK_SIZE" "$QUALITY"

        if [ $? -eq 0 ]; then
            size_png=$(stat -f%z "$png" 2>/dev/null || stat -c%s "$png")
            size_astc=$(stat -f%z "$astc" 2>/dev/null || stat -c%s "$astc")
            ratio=$(echo "scale=1; $size_png / $size_astc" | bc)
            echo "  ✓ $png ($size_png bytes) → $astc ($size_astc bytes) - ${ratio}× compression"
        else
            echo "  ✗ Failed"
        fi
        echo ""
    fi
done

# 更新 atlas 文件
for atlas in *.atlas; do
    if [ -f "$atlas" ] && [[ "$atlas" != *"-astc.atlas" ]]; then
        base="${atlas%.atlas}"
        astc_atlas="${base}-astc.atlas"

        echo "Creating: $astc_atlas"
        sed 's/\.png/.astc/g' "$atlas" > "$astc_atlas"
        echo "  ✓ Created $astc_atlas"
    fi
done

echo ""
echo "✅ Conversion complete!"
echo ""
echo "Format: LDR/Linear (matches PNG loading)"
echo "Metal: MTLPixelFormatASTC_${BLOCK_SIZE}_LDR"
echo ""
