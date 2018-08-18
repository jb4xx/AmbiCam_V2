import gohai.glvideo.*;


class WebCam {
  protected GLCapture cam;
  protected int captureWidth, captureHeight, captureFrameRate;
  protected float[] displayParamToFit; // Stored int the following order: x position / y position / width / height / scale applied
  
  
  // Constructor
  WebCam(PApplet p_parent, int p_Width, int p_Height, int p_frameRate) {
    cam = new GLCapture(p_parent, GLCapture.list()[0], p_Width, p_Height, p_frameRate);
    cam.start();
    
    while (cam.available() == false) {
      delay(10);
    }
    
    captureWidth = p_Width;
    captureHeight = p_Height;
    captureFrameRate = p_frameRate;
    
    // Set the display parameters to fit screen
    displayParamToFit = new float[5];
    if (captureWidth < width && captureHeight < height) {
      displayParamToFit[0] = (width - captureWidth) / 2.0;
      displayParamToFit[1] = (height - captureHeight) / 2.0;
      displayParamToFit[2] = captureWidth;
      displayParamToFit[3] = captureHeight;
      displayParamToFit[4] = 1;
    } else if ( (captureWidth / captureHeight) < (width / height) ) {
      displayParamToFit[3] = height;
      displayParamToFit[2] = (height * (captureWidth / (float)captureHeight));
      displayParamToFit[1] = 0;
      displayParamToFit[0] = ((width-displayParamToFit[2])/2.0);
      displayParamToFit[4] = height / (float)captureHeight;
    } else {
      displayParamToFit[2] = width;
      displayParamToFit[3] = (width * (captureHeight / (float)captureWidth));
      displayParamToFit[0] = 0;
      displayParamToFit[1] = ((height-displayParamToFit[3])/2.0);
      displayParamToFit[4] = width / (float)captureWidth;
    }
  }
  
  
  // Update the capture
  void read() {
    if (cam.available() == true) {
        cam.read();
      }
  }
  
  
  // display the capture and fit the screen
  void displayToFitScreen() {
    read();
    image(cam, displayParamToFit[0], displayParamToFit[1], displayParamToFit[2], displayParamToFit[3]);
  }
  

  // Return a copy of the last image captured
  PImage getSnapshot() {
    read();
    return cam.copy();
  }
  

  // Return the parameters needed to display an image from the webcam in order to fit the screen
  float[] getDisplayToFitScreenParameters() {
    return displayParamToFit;
  }
  
  
  // Return the width of the capture
  int width() {
    return captureWidth;
  }
  
  
  // Return the height of the capture
  int height() {
    return captureHeight;
  }

}
