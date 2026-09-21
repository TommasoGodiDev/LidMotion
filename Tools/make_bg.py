import sys
try:
    from AppKit import *
    from CoreGraphics import *
except ImportError:
    print("PyObjC not found")
    sys.exit(1)

width, height = 600, 400
colorSpace = CGColorSpaceCreateDeviceRGB()
bitmap = CGBitmapContextCreate(None, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast)

# Fill background with dark gray/gradient
CGContextSetRGBFillColor(bitmap, 0.15, 0.15, 0.16, 1.0)
CGContextFillRect(bitmap, CGRectMake(0, 0, width, height))

# Draw an arrow
CGContextBeginPath(bitmap)
CGContextMoveToPoint(bitmap, 250, 200)
CGContextAddLineToPoint(bitmap, 320, 200)
CGContextAddLineToPoint(bitmap, 310, 210)
CGContextMoveToPoint(bitmap, 320, 200)
CGContextAddLineToPoint(bitmap, 310, 190)
CGContextSetRGBStrokeColor(bitmap, 0.5, 0.5, 0.5, 1.0)
CGContextSetLineWidth(bitmap, 4.0)
CGContextStrokePath(bitmap)

# Draw text "Drag to Install"
# Using CoreText is complex in PyObjC. Let's just keep the arrow.
# Save to PNG
image = CGBitmapContextCreateImage(bitmap)
url = NSURL.fileURLWithPath_("background.png")
dest = CGImageDestinationCreateWithURL(url, "public.png", 1, None)
CGImageDestinationAddImage(dest, image, None)
CGImageDestinationFinalize(dest)
print("Saved background.png")
