import os
import subprocess

def create_svg(width=512, height=512, is_maskable=False):
    # If maskable, full bleed without border radius on the outer svg
    rx = 0 if is_maskable else int(width * 0.22)
    scale = 0.72 if is_maskable else 0.88
    offset_x = (width * (1 - scale)) / 2
    offset_y = (height * (1 - scale)) / 2

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">
  <defs>
    <!-- Background Gradient -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4f46e5" />
      <stop offset="50%" stop-color="#7c3aed" />
      <stop offset="100%" stop-color="#ec4899" />
    </linearGradient>

    <!-- Golden Wand Gradient -->
    <linearGradient id="goldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fef08a" />
      <stop offset="50%" stop-color="#fbbf24" />
      <stop offset="100%" stop-color="#f59e0b" />
    </linearGradient>

    <!-- Star Glow Gradient -->
    <radialGradient id="starGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="1" />
      <stop offset="40%" stop-color="#fef08a" stop-opacity="0.8" />
      <stop offset="100%" stop-color="#fbbf24" stop-opacity="0" />
    </radialGradient>

    <!-- Soft Overlay Glow -->
    <radialGradient id="topGlow" cx="30%" cy="20%" r="60%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.35" />
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0" />
    </radialGradient>

    <filter id="dropShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#0f172a" flood-opacity="0.35" />
    </filter>
    <filter id="glowFilter" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="6" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>

  <!-- Background Layer -->
  <rect x="0" y="0" width="{width}" height="{height}" rx="{rx}" fill="url(#bgGrad)" />
  <rect x="0" y="0" width="{width}" height="{height}" rx="{rx}" fill="url(#topGlow)" />

  <!-- Content Group scaled and centered -->
  <g transform="translate({offset_x}, {offset_y}) scale({scale})" filter="url(#dropShadow)">
    <!-- Base 512 coordinate system for artwork -->
    <g transform="scale({width/512})">
      
      <!-- Fairy Wand Stick -->
      <line x1="150" y1="380" x2="290" y2="240" stroke="#f1f5f9" stroke-width="14" stroke-linecap="round" />
      <line x1="150" y1="380" x2="290" y2="240" stroke="url(#goldGrad)" stroke-width="8" stroke-linecap="round" />

      <!-- Wand Star Head (Magical Starburst) -->
      <g transform="translate(305, 225)">
        <!-- Star glow aura -->
        <circle cx="0" cy="0" r="60" fill="url(#starGlow)" opacity="0.6" filter="url(#glowFilter)" />
        
        <!-- 4-point Diamond Star -->
        <path d="M 0,-50 Q 0,0 50,0 Q 0,0 0,50 Q 0,0 -50,0 Q 0,0 0,-50 Z" fill="#ffffff" />
        <path d="M 0,-40 Q 0,0 40,0 Q 0,0 0,40 Q 0,0 -40,0 Q 0,0 0,-40 Z" fill="url(#goldGrad)" />
        <circle cx="0" cy="0" r="12" fill="#ffffff" />
      </g>

      <!-- Little Sparkling Stars -->
      <!-- Star 1 (Top Left) -->
      <path d="M 140,140 Q 140,165 165,165 Q 140,165 140,190 Q 140,165 115,165 Q 140,165 140,140 Z" fill="#ffffff" opacity="0.9" />
      <!-- Star 2 (Right) -->
      <path d="M 400,280 Q 400,295 415,295 Q 400,295 400,310 Q 400,295 385,295 Q 400,295 400,280 Z" fill="#fef08a" opacity="0.85" />
      <!-- Star 3 (Bottom Left Spark) -->
      <circle cx="210" cy="340" r="5" fill="#ffffff" opacity="0.8" />
      <circle cx="340" cy="140" r="4" fill="#ffffff" opacity="0.7" />
      <circle cx="380" cy="190" r="6" fill="#fef08a" opacity="0.9" />

      <!-- Musical Note 1: Beamed Eighth Notes (Left/Center) -->
      <g transform="translate(160, 200) rotate(-12)" filter="url(#glowFilter)">
        <!-- Left Notehead -->
        <ellipse cx="25" cy="85" rx="18" ry="14" transform="rotate(-20 25 85)" fill="#ffffff" />
        <!-- Right Notehead -->
        <ellipse cx="85" cy="70" rx="18" ry="14" transform="rotate(-20 85 70)" fill="#ffffff" />
        <!-- Stems -->
        <rect x="36" y="20" width="8" height="66" rx="4" fill="#ffffff" />
        <rect x="96" y="05" width="8" height="66" rx="4" fill="#ffffff" />
        <!-- Beam Bar -->
        <polygon points="36,25 104,10 104,22 36,37" fill="#ffffff" />
      </g>

      <!-- Musical Note 2: Dancing Eighth Note (Top Right) -->
      <g transform="translate(320, 95) rotate(15)">
        <ellipse cx="20" cy="55" rx="15" ry="11" transform="rotate(-20 20 55)" fill="#ffffff" />
        <rect x="30" y="10" width="7" height="46" rx="3.5" fill="#ffffff" />
        <!-- Flag -->
        <path d="M 36,10 C 50,15 56,26 50,42 C 45,30 38,25 36,22 Z" fill="#ffffff" />
      </g>

    </g>
  </g>
</svg>'''
    return svg

def main():
    os.makedirs('icons', exist_ok=True)
    
    # 1. Standard SVG
    standard_svg = create_svg(512, 512, is_maskable=False)
    with open('icons/icon.svg', 'w', encoding='utf-8') as f:
        f.write(standard_svg)
    print("Created icons/icon.svg")

    # 2. Maskable SVG
    maskable_svg = create_svg(512, 512, is_maskable=True)
    with open('icons/icon-maskable.svg', 'w', encoding='utf-8') as f:
        f.write(maskable_svg)
    print("Created icons/icon-maskable.svg")

    # Target PNG outputs using sips
    targets = [
        ('icons/icon.svg', 'icons/icon-512.png', 512, 512),
        ('icons/icon.svg', 'icons/icon-192.png', 192, 192),
        ('icons/icon.svg', 'icons/apple-touch-icon.png', 180, 180),
        ('icons/icon.svg', 'icons/favicon.png', 32, 32),
        ('icons/icon-maskable.svg', 'icons/icon-maskable-512.png', 512, 512),
        ('icons/icon-maskable.svg', 'icons/icon-maskable-192.png', 192, 192),
    ]

    for src, dst, w, h in targets:
        cmd = ['sips', '-s', 'format', 'png', '-z', str(h), str(w), src, '--out', dst]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"Generated {dst} ({w}x{h})")
        else:
            print(f"Failed {dst}: {res.stderr}")

if __name__ == '__main__':
    main()
