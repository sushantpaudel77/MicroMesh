#!/bin/bash

# Download sample product images from Unsplash
# Clothing & fashion items - replace with actual product images

IMAGES_DIR="product-images"

echo "Creating images directory..."
mkdir -p "$IMAGES_DIR"

echo "Downloading sample clothing product images..."

# Product 1 - Premium White Oxford Shirt
curl -L "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&q=80" \
  -o "$IMAGES_DIR/prod-001.jpg"

# Product 2 - Chino Pants
curl -L "https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800&q=80" \
  -o "$IMAGES_DIR/prod-002.jpg"

# Product 3 - Floral Summer Dress
curl -L "https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=800&q=80" \
  -o "$IMAGES_DIR/prod-003.jpg"

# Product 4 - Leather Biker Jacket
curl -L "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800&q=80" -o "$IMAGES_DIR/prod-004.jpg"

# Product 5 - High-Waist Skinny Jeans
curl -L "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800&q=80" -o "$IMAGES_DIR/prod-005.jpg"

# Product 6 - Oversized Graphic Tee
curl -L "https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&q=80" -o "$IMAGES_DIR/prod-006.jpg"

# Product 7 - Knit Turtleneck Sweater
curl -L "https://images.unsplash.com/photo-1576871337632-b9aef4c17ab9?w=800&q=80" -o "$IMAGES_DIR/prod-007.jpg"

# Product 8 - Pleated Midi Skirt
curl -L "https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=800&q=80" -o "$IMAGES_DIR/prod-008.jpg"

# Product 9 - Puffer Quilted Vest
curl -L "https://images.unsplash.com/photo-1547949003-9792a18a2601?w=800&q=80" -o "$IMAGES_DIR/prod-009.jpg"

# Product 10 - Linen Wide-Leg Trousers
curl -L "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&q=80" \
  -o "$IMAGES_DIR/prod-010.jpg"

# Product 11 - Denim Trucker Jacket
curl -L "https://images.unsplash.com/photo-1601333144130-8cbb312386b6?w=800&q=80" -o "$IMAGES_DIR/prod-011.jpg"

# Product 12 - Wrap Blouse
curl -L "https://images.unsplash.com/photo-1564257631407-4deb1f99d992?w=800&q=80" -o "$IMAGES_DIR/prod-012.jpg"

# Product 13 - Athletic Jogger Pants
curl -L "https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=800&q=80" -o "$IMAGES_DIR/prod-013.jpg"

# Product 14 - Wool Blend Blazer
curl -L "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&q=80" -o "$IMAGES_DIR/prod-014.jpg"

# Product 15 - Ribbed Crop Top
curl -L "https://images.unsplash.com/photo-1562157873-818bc0726f68?w=800&q=80" -o "$IMAGES_DIR/prod-015.jpg"

# Product 16 - Maxi Boho Dress
curl -L "https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=800&q=80" -o "$IMAGES_DIR/prod-016.jpg"

# Product 17 - Cargo Shorts
curl -L "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&q=80" \
  -o "$IMAGES_DIR/prod-017.jpg"

# Product 18 - Sports Bra
curl -L "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80" -o "$IMAGES_DIR/prod-018.jpg"

# Product 19 - Trench Coat
curl -L "https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800&q=80" -o "$IMAGES_DIR/prod-019.jpg"

# Product 20 - Hooded Zip-Up Sweatshirt
curl -L "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800&q=80" \
  -o "$IMAGES_DIR/prod-020.jpg"

echo ""
echo "✓ Downloaded 20 clothing product images"
echo "Images saved in: $IMAGES_DIR/"
echo ""
echo "Next step: Run upload-images-to-s3.sh to upload to S3"