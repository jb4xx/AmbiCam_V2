class ColorDetector {
  protected int nbOfXLed, nbOfYLed;
  protected int qualityLevel;
  protected float tvScreenRatio; // height/width
  protected Tetragon tvScreen;
  protected ArrayList<Doublet> reshapeParam;
  protected int reshapeW, reshapeH; // The width and height of the reshaped TV screen
  protected WebCam cam;
  protected boolean calibrationDone;
  protected float[] reshapedScreenDisplayParamToFit;
  

  // Constructor
  ColorDetector(WebCam p_cam, int p_nbOfXLed, int p_nbOfYLed, int p_qualityLevel, float p_tvScreenRatio) {
    cam = p_cam;
    nbOfXLed = p_nbOfXLed;
    nbOfYLed = p_nbOfYLed;
    qualityLevel = p_qualityLevel;
    tvScreenRatio = p_tvScreenRatio;
    reshapeParam = new ArrayList<Doublet>();
    calibrationDone = false;
  }


  // Compute the distance between two colors
  // Minimum is 0, maximum is 195075
  private int getColorDistance(color ref, color target) {
    int deltaR = (target >> 16 & 0xFF) - (ref >> 16 & 0xFF);
    int deltaG = (target >> 8 & 0xFF) - (ref >> 8 & 0xFF);
    int deltaB = (target & 0xFF) - (ref & 0xFF);

    return deltaR * deltaR + deltaG * deltaG + deltaB * deltaB;
  }


  // Return the index of a pixel based on is x and y position
  private int getIndex(int x, int y, int w) {
    return x + y * w;
  }


  // Display a preview of the TV mask
  void displayTvScreenMaskPreview(int threshold) {
    cam.displayToFitScreen();
    float[] displayParam = cam.getDisplayToFitScreenParameters();
    image(getTvScreenMask(cam.getSnapshot(), threshold), displayParam[0], displayParam[1], displayParam[2], displayParam[3]);
  }
  
  
  // A faster version(??) of displayTvScreenMaskPreview but less accurate
  void displayFastTvScreenMaskPreview(int threshold) {
    PImage camPic = cam.getSnapshot();
    PImage tvScreenMaskPreview = createImage(cam.width(), cam.height(), ARGB);
    color refColor;
    refColor = camPic.get((int)(camPic.width/2), (int)(camPic.height/2));

    tvScreenMaskPreview.loadPixels();
    camPic.loadPixels();
    for (int i = 0; i < camPic.width * camPic.height; i++) {
      if (getColorDistance(refColor, camPic.pixels[i]) < threshold) {
        tvScreenMaskPreview.pixels[i] = color(255, 0, 0, 100);
      } else {
        tvScreenMaskPreview.pixels[i] = color(0, 0, 0, 0);
      }
    }
    tvScreenMaskPreview.updatePixels();

    cam.displayToFitScreen();
    float[] displayParam = cam.getDisplayToFitScreenParameters();
    image(tvScreenMaskPreview, displayParam[0], displayParam[1], displayParam[2], displayParam[3]);
  }


  // Return a black and white image where the tv screen is white and the rest is black
  private PImage getTvScreenMask(PImage camPic, float threshold) {
    PImage tvScreenMask = createImage(camPic.width, camPic.height, ARGB); // the result image
    color refColor = camPic.get((int)(camPic.width/2), (int)(camPic.height/2)); // The color use to detect if a pixel is part of the screen or not
    boolean[][] pixelIsAlreadySelected = new boolean[camPic.width][camPic.height]; // Use to avoid computing several time the same pixel
    ArrayList<PVector> pixelsToBeChecked = new ArrayList<PVector>(); // The list of all the pixels that need to be checked

    if (camPic.width == 0 || camPic.height == 0) {
      return createImage(0, 0, RGB);
    }

    // Initialization
    pixelsToBeChecked.add(new PVector(camPic.width/2, camPic.height/2));
    pixelIsAlreadySelected[camPic.width/2][camPic.height/2] = true;

    tvScreenMask.loadPixels();
    camPic.loadPixels();
    while (pixelsToBeChecked.size() > 0) {
      // Get the coordinate of the pixel to analyse
      int x = (int)pixelsToBeChecked.get(0).x;
      int y = (int)pixelsToBeChecked.get(0).y;
      int idx = getIndex(x, y, camPic.width);

      // Check if the point is in the selection and if so, spread it (in the image range)
      if (getColorDistance(refColor, camPic.pixels[idx]) < threshold) {
        tvScreenMask.pixels[idx] = color(255, 0, 0, 100);

        // Spread the pixels
        if (x+1 < camPic.width) {
          if (pixelIsAlreadySelected[x+1][y] == false) {
            pixelsToBeChecked.add(new PVector(x+1, y));
            pixelIsAlreadySelected[x+1][y] = true;
          }
        }

        if (x-1 > 0) {
          if (pixelIsAlreadySelected[x-1][y] == false) {
            pixelsToBeChecked.add(new PVector(x-1, y));
            pixelIsAlreadySelected[x-1][y] = true;
          }
        }

        if (y+1 < camPic.height) {
          if (pixelIsAlreadySelected[x][y+1] == false) {
            pixelsToBeChecked.add(new PVector(x, y+1)); 
            pixelIsAlreadySelected[x][y+1] = true;
          }
        }

        if (y-1 > 0) {
          if (pixelIsAlreadySelected[x][y-1] == false) {
            pixelsToBeChecked.add(new PVector(x, y-1)); 
            pixelIsAlreadySelected[x][y-1] = true;
          }
        }
      } else {
        tvScreenMask.pixels[idx] = color(0, 0, 0, 0);
      }

      // Remove the pixel from the list of the pixel to analyse
      pixelsToBeChecked.remove(0);
    } 
    tvScreenMask.updatePixels();
    return tvScreenMask;
  }


  // Bake the operations needed to transform the screen to a perfect rectangle
  void bake(float threshold) {
    PImage camPic = cam.getSnapshot();
    PImage tvScreenMask = getTvScreenMask(camPic, threshold);
    tvScreen = getTvScreen(tvScreenMask, 20);

    // Get render size of the reshaped tv screen
    reshapeW = (int)(max(tvScreen.getCorner("tr").x, tvScreen.getCorner("br").x) - max(tvScreen.getCorner("tl").x, tvScreen.getCorner("bl").x));
    reshapeH = (int)(reshapeW * tvScreenRatio);
    setReshapedScreenDisplayParamToFit();

    // Bake the reshaping parameters
    Tetragon reshapedTvScreen = new Tetragon(new PVector(0, 0), new PVector(reshapeW, 0), new PVector(reshapeW, reshapeH), new PVector(0, reshapeH)); // A rectangle with the same ratio as the TV
    ArrayList<Tetragon> tvScreenGrid = tvScreen.subdivide(qualityLevel);
    ArrayList<Tetragon> reshapedTvScreenGrid = reshapedTvScreen.subdivide(qualityLevel);

    int lowI = (int)((reshapeW / (float)nbOfXLed) * 1.1); // Those 4 variables are used to limit the reshaping to only the interested areas
    int highI = reshapeW - lowI;
    int lowJ = (int)((reshapeH / (float)nbOfYLed) * 1.1);
    int highJ = reshapeH - lowJ;

    reshapeParam.clear();
    for (int n = 0; n < reshapedTvScreenGrid.size(); n++) {
      PVector tlc, trc, blc, tlc2, trc2, brc2, blc2;
      tlc = reshapedTvScreenGrid.get(n).getCorner("tl");
      trc = reshapedTvScreenGrid.get(n).getCorner("tr");
      blc = reshapedTvScreenGrid.get(n).getCorner("bl");

      tlc2 = tvScreenGrid.get(n).getCorner("tl");
      trc2 = tvScreenGrid.get(n).getCorner("tr");
      brc2 = tvScreenGrid.get(n).getCorner("br");
      blc2 = tvScreenGrid.get(n).getCorner("bl");

      for (int i = (int)tlc.x; i < (int)trc.x; i++) {
        for (int j = (int)tlc.y; j < (int)blc.y; j++) {

          if ((i < lowI || i > highI) || (j < lowJ || j > highJ)) {
            float xPercentage = (float)(i - tlc.x) / (float)(trc.x - tlc.x);
            float yPercentage = (float)(j - tlc.y) / (float)(blc.y - tlc.y);

            float xTarget = tlc2.x * (1.0-yPercentage) * (1.0-xPercentage) + trc2.x * (1.0-yPercentage) * xPercentage + brc2.x * yPercentage * xPercentage + blc2.x * yPercentage * (1.0-xPercentage);
            float yTarget = tlc2.y * (1.0-yPercentage) * (1.0-xPercentage) + trc2.y * (1.0-yPercentage) * xPercentage + brc2.y * yPercentage * xPercentage + blc2.y * yPercentage * (1.0-xPercentage);

            reshapeParam.add(new Doublet(getIndex(i, j, reshapeW), getIndex((int)xTarget, (int)yTarget, camPic.width)));
          }
        }
      }
    }

    calibrationDone = true;
  }


  // Return a tetragon representing the tv screen
  private Tetragon getTvScreen(PImage maskPic, int ctrlAreaSize) {
    PVector tlCorner = getCorner(maskPic, 0, maskPic.width / 2, 0, maskPic.height / 2, ctrlAreaSize);
    PVector trCorner = getCorner(maskPic, maskPic.width / 2, maskPic.width, 0, maskPic.height / 2, ctrlAreaSize);
    PVector brCorner = getCorner(maskPic, 0, maskPic.width / 2, maskPic.height / 2, maskPic.height, ctrlAreaSize);
    PVector blCorner = getCorner(maskPic, maskPic.width / 2, maskPic.width, maskPic.height / 2, maskPic.height, ctrlAreaSize);

    return new Tetragon(tlCorner, trCorner, brCorner, blCorner);
  }


  // Find and return the coordinates of the corner in an area of maskpic
  private PVector getCorner(PImage maskPic, int xlBound, int xuBound, int ylBound, int yuBound, int ctrlAreaSize) {
    int minVal = (ctrlAreaSize * 2) * (ctrlAreaSize * 2) * 255;
    int tempVal;
    PVector corner = new PVector(0, 0);

    for (int x = xlBound; x < xuBound; x++) {
      for (int y = ylBound; y < yuBound; y++) {

        if ((maskPic.pixels[getIndex(x, y, maskPic.width)] >> 16 & 0xFF) > 0) {

          tempVal = 0;
          for (int dx = -ctrlAreaSize; dx <= ctrlAreaSize; dx++) {
            for (int dy = -ctrlAreaSize; dy <= ctrlAreaSize; dy++) {
              int idx = getIndex(x + dx, y + dy, maskPic.width);
              if (idx > -1 && idx < maskPic.pixels.length) {
                tempVal += (maskPic.pixels[idx] >> 16 & 0xFF);
              }
            }
          }

          if (tempVal < minVal) {
            minVal = tempVal;
            corner.set(x, y);
          }
        }
      }
    }

    return corner;
  }


  // Return the state of the calibration
  boolean isCalibrated() {
    return calibrationDone;
  }


  // Return the reshaped tv Screen
  private PImage getReshapedTvScreen() {
    PImage camPic = cam.getSnapshot();
    PImage result = new PImage(reshapeW, reshapeH, RGB);

    camPic.loadPixels();
    result.loadPixels();

    for (int i = 0; i < reshapeParam.size(); i++) {
      result.pixels[reshapeParam.get(i).v1] = camPic.pixels[reshapeParam.get(i).v2];
    }
    result.updatePixels();

    return result;
  }
  
  
  // Display a rectangle around the tv screen
  void displayTvScreenPosition(color strokeColor) {
    PVector pt1, pt2, pt3, pt4;
    float[] displayParam = cam.getDisplayToFitScreenParameters();
    PVector offset = new PVector(displayParam[0], displayParam[1]);
    pt1 = tvScreen.getCorner("tl").copy();
    pt2 = tvScreen.getCorner("tr").copy();
    pt3 = tvScreen.getCorner("br").copy();
    pt4 = tvScreen.getCorner("bl").copy();
    
    pt1.mult(displayParam[4]).add(offset);
    pt2.mult(displayParam[4]).add(offset);
    pt3.mult(displayParam[4]).add(offset);
    pt4.mult(displayParam[4]).add(offset);

    cam.displayToFitScreen();
    noFill();
    stroke(strokeColor);
    strokeWeight(4);
    line(pt1.x, pt1.y, pt2.x, pt2.y);
    line(pt2.x, pt2.y, pt3.x, pt3.y);
    line(pt3.x, pt3.y, pt4.x, pt4.y);
    line(pt4.x, pt4.y, pt1.x, pt1.y);
  }
  
  
  private void setReshapedScreenDisplayParamToFit() {
    reshapedScreenDisplayParamToFit = new float[5];
    if (reshapeW < width && reshapeH < height) {
      reshapedScreenDisplayParamToFit[0] = (width - reshapeW) / 2.0;
      reshapedScreenDisplayParamToFit[1] = (height - reshapeH) / 2.0;
      reshapedScreenDisplayParamToFit[2] = reshapeW;
      reshapedScreenDisplayParamToFit[3] = reshapeH;
      reshapedScreenDisplayParamToFit[4] = 1;
    } else if ( (reshapeW / reshapeH) < (width / height) ) {
      reshapedScreenDisplayParamToFit[3] = height;
      reshapedScreenDisplayParamToFit[2] = (height * (reshapeW / (float)reshapeH));
      reshapedScreenDisplayParamToFit[1] = 0;
      reshapedScreenDisplayParamToFit[0] = ((width-reshapedScreenDisplayParamToFit[2])/2.0);
      reshapedScreenDisplayParamToFit[4] = height / (float)reshapeH;
    } else {
      reshapedScreenDisplayParamToFit[2] = width;
      reshapedScreenDisplayParamToFit[3] = (width * (reshapeH / (float)reshapeW));
      reshapedScreenDisplayParamToFit[0] = 0;
      reshapedScreenDisplayParamToFit[1] = ((height-reshapedScreenDisplayParamToFit[3])/2.0);
      reshapedScreenDisplayParamToFit[4] = width / (float)reshapeW;
    }
  }
  
  
  // Display the reshaped screen
  void displayReshapedTvScreen() {
    image(getReshapedTvScreen(), reshapedScreenDisplayParamToFit[0], reshapedScreenDisplayParamToFit[1], reshapedScreenDisplayParamToFit[2], reshapedScreenDisplayParamToFit[3]);
  }
  
  
  // Return, in physical order, the color of each LEDs
  ArrayList<Integer> getLedsColor() {
    PImage tvScreen = getReshapedTvScreen();
    ArrayList<Integer> ledsColor = new ArrayList<Integer>();
    int x, y, xStep, yStep;
    
    tvScreen.resize(nbOfXLed, nbOfYLed);
    x = nbOfXLed / 2 - 1;
    y = nbOfYLed - 1;
    xStep = -1;
    yStep = 0;
    
    for (int i = 0; i < 2 * (nbOfXLed + nbOfYLed) - 1; i++) {
      ledsColor.add(tvScreen.get(x, y));
      
      x += xStep;
      y += yStep;
      
      if (x < 0) {
        x = 0;
        xStep = 0;
        yStep = -1;
      } else if (y < 0) {
        y = 0;
        xStep = 1;
        yStep = 0;
      } else if (x > nbOfXLed - 1) {
        x = nbOfXLed - 1;
        xStep = 0;
        yStep = 1;
      } else if (y > nbOfYLed - 1) {
        y = nbOfYLed - 1;
        xStep = -1;
        yStep = 0;
      }
    }
    
    return ledsColor;
  }
  
  
  // Display the color of the LEDs on screen
  void displayLedsColor() {
    ArrayList<Integer> ledsColor = getLedsColor();
    int rectW = width / nbOfXLed;
    int rectH = height / nbOfYLed;
    int rectOffset = 3;
    int x, y, xStep, yStep;
    x = nbOfXLed / 2 - 1;
    y = nbOfYLed - 1;
    xStep = -1;
    yStep = 0;
    
    noStroke();
    for (int i = 0; i < 2 * (nbOfXLed + nbOfYLed) - 1; i++) {
      fill(ledsColor.get(i));
      rect(x * rectW + rectOffset, y * rectH + rectOffset, rectW - 2 * rectOffset, rectH - 2 * rectOffset);
      
      x += xStep;
      y += yStep;
      
      if (x < 0) {
        x = 0;
        xStep = 0;
        yStep = -1;
      } else if (y < 0) {
        y = 0;
        xStep = 1;
        yStep = 0;
      } else if (x > nbOfXLed - 1) {
        x = nbOfXLed - 1;
        xStep = 0;
        yStep = 1;
      } else if (y > nbOfYLed - 1) {
        y = nbOfYLed - 1;
        xStep = -1;
        yStep = 0;
      }
    }
  }
  
  
  // Display the camera feed
  void displayCameraFeed() {
    cam.displayToFitScreen();
  }
}
